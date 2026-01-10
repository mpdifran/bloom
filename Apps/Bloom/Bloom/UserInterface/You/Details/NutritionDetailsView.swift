//
//  NutritionDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-05.
//

import SFSafeSymbols
import SwiftUI
import Charts
import TelemetryDeck
import HealthKit
import CoreHealth
import BloomFoundation

struct NutritionDetailsView: View {

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var nutritionDetails: NutritionMonthlySummary.Details?
  @State private var dailyFiber = [DateQuantitySample]()
  @State private var dailySugar = [DateQuantitySample]()
  @State private var dailyCholesterol = [DateQuantitySample]()

  @State private var presentedSheet: AnyView?
  @State private var hasVitaminData = false
  @State private var hasMineralData = false

  var hasNoData: Bool {
    nutritionDetails == nil
  }

  var body: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)

      if hasNoData {
        emptyView
      } else {
        macrosChart
          .cardContainer(includePadding: false)
        vitaminsChart
          .cardContainer()
        mineralsChart
          .cardContainer()
        cholesterolChart
          .cardContainer()
        fiberChart
          .cardContainer()
        sugarChart
          .cardContainer()

        HealthCitationLinkView(
          url: .dietaryGuidelinesForAmericans,
          title: "Recommended ranges based on the USDA's Dietary Guidelines for Americans."
        )
        .padding(.horizontal)
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Nutrition",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Nutrition")
    .navigationBarTitleDisplayMode(.inline)
    .groupedBackground()
    .sheet($presentedSheet)
    .animation(.default, value: selectedPeriod)
    .task(id: selectedPeriod) {
      let details = await HealthStoreFetcher.shared.fetchNutritionMonthlySummaryDetails(
        dateRange: selectedPeriod.dateRange
      )
      await MainActor.run {
        self.nutritionDetails = details
        self.hasVitaminData = details.averageVitaminA != nil ||
          details.averageVitaminB6 != nil ||
          details.averageVitaminB12 != nil ||
          details.averageVitaminC != nil ||
          details.averageVitaminD != nil ||
          details.averageVitaminE != nil
        self.hasMineralData = details.averageCalcium != nil ||
          details.averageIron != nil ||
          details.averageMagnesium != nil ||
          details.averagePotassium != nil ||
          details.averageSodium != nil ||
          details.averageZinc != nil
      }
    }
    .task(id: selectedPeriod) {
      let dailySamples = await HealthStoreFetcher.shared.fetchCollatedQuantity(
        for: .dietarySugar,
        unit: .gram(),
        interval: DateComponents(day: 1),
        options: [.cumulativeSum],
        dateRange: selectedPeriod.dateRange
      )

      let samples: [DateQuantitySample]
      if selectedPeriod.aggregatesByWeek {
        let grouped = Dictionary(grouping: dailySamples) { sample in
          Calendar.current.dateInterval(of: .weekOfYear, for: sample.date)?.start ?? sample.date
        }
        samples = grouped.map { (weekStart, weekSamples) in
          let average = weekSamples.map { $0.quantity.doubleValue(for: .gram()) }.average(keyPath: \.self)
          return DateQuantitySample(date: weekStart, quantity: HKQuantity(unit: .gram(), doubleValue: average))
        }.sorted { $0.date < $1.date }
      } else {
        samples = dailySamples
      }

      await MainActor.run {
        self.dailySugar = samples
      }
    }
    .task(id: selectedPeriod) {
      let dailySamples = await HealthStoreFetcher.shared.fetchCollatedQuantity(
        for: .dietaryFiber,
        unit: .gram(),
        interval: DateComponents(day: 1),
        options: [.cumulativeSum],
        dateRange: selectedPeriod.dateRange
      )

      let samples: [DateQuantitySample]
      if selectedPeriod.aggregatesByWeek {
        let grouped = Dictionary(grouping: dailySamples) { sample in
          Calendar.current.dateInterval(of: .weekOfYear, for: sample.date)?.start ?? sample.date
        }
        samples = grouped.map { (weekStart, weekSamples) in
          let average = weekSamples.map { $0.quantity.doubleValue(for: .gram()) }.average(keyPath: \.self)
          return DateQuantitySample(date: weekStart, quantity: HKQuantity(unit: .gram(), doubleValue: average))
        }.sorted { $0.date < $1.date }
      } else {
        samples = dailySamples
      }

      await MainActor.run {
        self.dailyFiber = samples
      }
    }
    .task(id: selectedPeriod) {
      let dailySamples = await HealthStoreFetcher.shared.fetchCollatedQuantity(
        for: .dietaryCholesterol,
        unit: .gramUnit(with: .milli),
        interval: DateComponents(day: 1),
        options: [.cumulativeSum],
        dateRange: selectedPeriod.dateRange
      )

      let samples: [DateQuantitySample]
      if selectedPeriod.aggregatesByWeek {
        let grouped = Dictionary(grouping: dailySamples) { sample in
          Calendar.current.dateInterval(of: .weekOfYear, for: sample.date)?.start ?? sample.date
        }
        samples = grouped.map { (weekStart, weekSamples) in
          let average = weekSamples.map { $0.quantity.doubleValue(for: .gramUnit(with: .milli)) }.average(keyPath: \.self)
          return DateQuantitySample(date: weekStart, quantity: HKQuantity(unit: .gramUnit(with: .milli), doubleValue: average))
        }.sorted { $0.date < $1.date }
      } else {
        samples = dailySamples
      }

      await MainActor.run {
        self.dailyCholesterol = samples
      }
    }
    .onAppear {
      TelemetryDeck.viewScreen("Nutrition Vital Details")
    }
  }
}

private extension NutritionDetailsView {

  var emptyView: some View {
    ContentUnavailableView {
      Label("No Data Available", systemSymbol: .forkKnife)
    } description: {
      Text("Track your food to get more insights into your Nutrition.")
    } actions: {
      Button("Log Food"){
        presentedSheet = FoodLoggingActionCardView().asAny
      }
      .buttonStyle(.primary)
    }
  }

  @ViewBuilder
  var macrosChart: some View {
    if let details = nutritionDetails, let macros = details.macros {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Macros",
          valueLabel: "",
          value: details.macroStatus()?.rawValue ?? ""
        )
        .padding(.horizontal)

        Divider()

        PillRangeChart(
          title: "Protein",
          quantityString: macros.protein.displayString(for: .gram()),
          unitString: "%",
          value: (macros.proteinPercent * 100),
          minValue: HealthGoalProvider.shared.recommendedDailyProteinPercentOfDietaryEnergy().lowerBound * 100,
          maxValue: HealthGoalProvider.shared.recommendedDailyProteinPercentOfDietaryEnergy().upperBound * 100
        )
        .tint(.protein)

        Divider()

        PillRangeChart(
          title: "Carbohydrates",
          quantityString: macros.carbohydrates.displayString(for: .gram()),
          unitString: "%",
          value: (macros.carbsPercent * 100),
          minValue: HealthGoalProvider.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy().lowerBound * 100,
          maxValue: HealthGoalProvider.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy().upperBound * 100
        )
        .tint(.carbohydrates)

        Divider()

        PillRangeChart(
          title: "Fat",
          quantityString: macros.fat.displayString(for: .gram()),
          unitString: "%",
          value: (macros.fatPercent * 100),
          minValue: HealthGoalProvider.shared.recommendedDailyFatPercentOfDietaryEnergy().lowerBound * 100,
          maxValue: HealthGoalProvider.shared.recommendedDailyFatPercentOfDietaryEnergy().upperBound * 100
        )
        .tint(.fat)
      }
      .padding(.vertical)
    }
  }

  @ViewBuilder
  var vitaminsChart: some View {
    if let details = nutritionDetails, hasVitaminData {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Vitamins",
          valueLabel: "",
          value: ""
        )

        Divider()

        if let vitaminA = details.averageVitaminA?.doubleValue(for: .gramUnit(with: .micro)) {
          let goal = HealthGoalProvider.shared.recommendedDailyIntakeForVitaminA()
          CapsuleRangeChart(
            title: "Vitamin A",
            unitString: "mcg",
            value: vitaminA,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .micro)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .micro))
          )
          .tint(.vitaminA)
        }
        if let vitaminB6 = details.averageVitaminB6?.doubleValue(for: .gramUnit(with: .milli)) {
          let goal = HealthGoalProvider.shared.recommendedDailyIntakeForVitaminB6()
          CapsuleRangeChart(
            title: "Vitamin B6",
            unitString: "mg",
            value: vitaminB6,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
          )
          .tint(.vitaminB6)
        }
        if let vitaminB12 = details.averageVitaminB12?.doubleValue(for: .gramUnit(with: .micro)) {
          let goal = HealthGoalProvider.shared.recommendedMinDailyIntakeForVitaminB12()
          CapsuleRangeChart(
            title: "Vitamin B12",
            unitString: "mcg",
            value: vitaminB12,
            minValue: goal.doubleValue(for: .gramUnit(with: .micro)),
            maxValue: 2000
          )
          .tint(.vitaminB12)
        }
        if let vitaminC = details.averageVitaminC?.doubleValue(for: .gramUnit(with: .milli)) {
          let goal = HealthGoalProvider.shared.recommendedDailyIntakeForVitaminC()
          CapsuleRangeChart(
            title: "Vitamin C",
            unitString: "mg",
            value: vitaminC,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
          )
          .tint(.vitaminC)
        }
        if let vitaminD = details.averageVitaminD?.doubleValue(for: .gramUnit(with: .micro)) {
          let goal = HealthGoalProvider.shared.recommendedDailyIntakeForVitaminD()
          CapsuleRangeChart(
            title: "Vitamin D",
            unitString: "mcg",
            value: vitaminD,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .micro)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .micro))
          )
          .tint(.vitaminD)
        }
        if let vitaminE = details.averageVitaminE?.doubleValue(for: .gramUnit(with: .milli)) {
          let goal = HealthGoalProvider.shared.recommendedDailyIntakeForVitaminE()
          CapsuleRangeChart(
            title: "Vitamin E",
            unitString: "mg",
            value: vitaminE,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
          )
          .tint(.vitaminE)
        }
      }
    }
  }

  @ViewBuilder
  var mineralsChart: some View {
    if let details = nutritionDetails, hasMineralData {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Minerals",
          valueLabel: "",
          value: ""
        )

        Divider()

        if let calcium = details.averageCalcium?.doubleValue(for: .gramUnit(with: .milli)) {
          let goal = HealthGoalProvider.shared.recommendedIntakeForCalcium()
          CapsuleRangeChart(
            title: "Calcium",
            unitString: "mg",
            value: calcium,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
          )
          .tint(.calcium)
        }
        if let iron = details.averageIron?.doubleValue(for: .gramUnit(with: .milli)) {
          let goal = HealthGoalProvider.shared.recommendedDailyIntakeForIron()
          CapsuleRangeChart(
            title: "Iron",
            unitString: "mg",
            value: iron,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
          )
          .tint(.iron)
        }
        if let magnesium = details.averageMagnesium?.doubleValue(for: .gramUnit(with: .milli)) {
          let goal = HealthGoalProvider.shared.recommendedDailyIntakeForMagnesium()
          CapsuleRangeChart(
            title: "Magnesium",
            unitString: "mg",
            value: magnesium,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
          )
          .tint(.magnesium)
        }
        if let potassium = details.averagePotassium?.doubleValue(for: .gramUnit(with: .milli)) {
          let goal = HealthGoalProvider.shared.recommendedDailyIntakeForPotassium()
          CapsuleRangeChart(
            title: "Potassium",
            unitString: "mg",
            value: potassium,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
          )
          .tint(.potassium)
        }
        if let sodium = details.averageSodium?.doubleValue(for: .gramUnit(with: .milli)) {
          let goal = HealthGoalProvider.shared.recommendedDailyIntakeForSodium()
          CapsuleRangeChart(
            title: "Sodium",
            unitString: "mg",
            value: sodium,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
          )
          .tint(.sodium)
        }
        if let zinc = details.averageZinc?.doubleValue(for: .gramUnit(with: .milli)) {
          let goal = HealthGoalProvider.shared.recommendedDailyIntakeForZinc()
          CapsuleRangeChart(
            title: "Zinc",
            unitString: "mg",
            value: zinc,
            minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
            maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
          )
          .tint(.zinc)
        }
      }
    }
  }

  @ViewBuilder
  var fiberChart: some View {
    if
      let details = nutritionDetails,
      let averageFiber = details.averageFiber,
      averageFiber.doubleValue(for: .gram()) >= 1
    {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Fiber",
          value: averageFiber.displayString(for: .gram())
        )

        Chart{
          ForEach(dailyFiber) { sample in
            BarMark(
              x: .value("Date", sample.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("Daily Fiber", sample.quantity.doubleValue(for: .gram()))
            )
            .foregroundStyle(.fiber)
          }

          let goal = HealthGoalProvider.shared.recommendedMinDailyIntakeForFiber()
          RuleMark(
            y: .value("Min Fiber", goal.doubleValue(for: .gram()))
          )
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(.fiber)

          RectangleMark(
            yStart: .value("Max Fiber", goal.doubleValue(for: .gram()) * 2),
            yEnd: .value("Min Fiber", goal.doubleValue(for: .gram()))
          )
          .foregroundStyle(
            LinearGradient(
              colors: [
                .fiber.opacity(0.3),
                .clear
              ],
              startPoint: .bottom,
              endPoint: .top
            )
          )
        }
        .frame(height: 160)
      }
    }
  }

  @ViewBuilder
  var cholesterolChart: some View {
    if
      let details = nutritionDetails,
      let averageCholesterol = details.averageCholesterol,
      averageCholesterol.doubleValue(for: .gramUnit(with: .milli)) >= 1
    {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Cholesterol",
          value: averageCholesterol.displayString(for: .gramUnit(with: .milli))
        )

        Chart{
          ForEach(dailyCholesterol) { sample in
            BarMark(
              x: .value("Date", sample.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("Daily Cholesterol", sample.quantity.doubleValue(for: .gramUnit(with: .milli)))
            )
            .foregroundStyle(.cholesterol)
          }

          if let goal = HealthGoalProvider.shared.recommendedDailyMaxCholesterol() {
            RuleMark(
              y: .value("Max Cholesterol", goal.doubleValue(for: .gramUnit(with: .milli)))
            )
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(.cholesterol)

            RectangleMark(
              yStart: .value("", 0),
              yEnd: .value("Max Cholesterol", goal.doubleValue(for: .gramUnit(with: .milli)))
            )
            .foregroundStyle(.cholesterol.opacity(0.3))
          }
        }
        .frame(height: 160)
      }
    }
  }

  @ViewBuilder
  var sugarChart: some View {
    if
      let details = nutritionDetails,
      let averageSugar = details.averageSugar,
      averageSugar.doubleValue(for: .gram()) >= 1
    {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Sugar",
          value: averageSugar.displayString(for: .gram())
        )

        Chart{
          ForEach(dailySugar) { sample in
            BarMark(
              x: .value("Date", sample.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("Daily Sugar", sample.quantity.doubleValue(for: .gram()))
            )
            .foregroundStyle(.sugar)
          }

          let goal = HealthGoalProvider.shared.recommendedMaxDailyIntakeForSugar()
          RuleMark(
            y: .value("Max Sugar", goal.doubleValue(for: .gram()))
          )
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(.sugar)

          RectangleMark(
            yStart: .value("", 0),
            yEnd: .value("Max Sugar", goal.doubleValue(for: .gram()))
          )
          .foregroundStyle(.sugar.opacity(0.3))
        }
        .frame(height: 160)
      }
    }
  }
}

#Preview {
  NavigationStack {
    NutritionDetailsView()
  }
}
