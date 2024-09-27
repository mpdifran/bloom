//
//  NutritionDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-05.
//

import SwiftUI
import Charts
import TelemetryDeck

private extension NutritionDetailsView {
    enum EnergyChartScope {
        case monthlyAverage
        case daily
    }
}

struct NutritionDetailsView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared

    @State private var dailyEnergy = [DateQuantitySampleLegacy]()
    @State private var fiberChartScope = EnergyChartScope.monthlyAverage
    @State private var dailyFiber = [DateQuantitySampleLegacy]()
    @State private var sugarChartScope = EnergyChartScope.monthlyAverage
    @State private var dailySugar = [DateQuantitySampleLegacy]()
    @State private var caffeineChartScope = EnergyChartScope.monthlyAverage
    @State private var dailyCaffeine = [DateQuantitySampleLegacy]()
    @State private var waterChartScope = EnergyChartScope.monthlyAverage
    @State private var dailyWater = [DateQuantitySample]()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                netEnergyChart
                    .cardContainer()
                macrosChart
                    .cardContainer(includePadding: false)
                vitaminsChart
                    .cardContainer()
                mineralsChart
                    .cardContainer()
                waterChart
                    .cardContainer()
                fiberChart
                    .cardContainer()
                sugarChart
                    .cardContainer()
                caffeineChart
                    .cardContainer()
            }
            .padding()
            .horizontallyCentered()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VitalSummaryDetailTitleView(
                    title: "Nutrition",
                    subtitle: "Last 30 Days"
                )
            }
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
        .groupedBackground()
        .animation(.default, value: fiberChartScope)
        .animation(.default, value: sugarChartScope)
        .animation(.default, value: caffeineChartScope)
        .task {
            let samples = await HealthManager.shared.fetchNetEnergy(numPrevDays: 30)
            await MainActor.run {
                self.dailyEnergy = samples
            }
        }
        .task {
            let samples = await HealthManager.shared.fetchNutritionalDailyQuantities(
                quantityTypeID: .dietarySugar,
                unit: .gram(),
                numPrevDays: 30
            )
            await MainActor.run {
                self.dailySugar = samples
            }
        }
        .task {
            let samples = await HealthManager.shared.fetchNutritionalDailyQuantities(
                quantityTypeID: .dietaryCaffeine,
                unit: .gramUnit(with: .milli),
                numPrevDays: 30
            )
            await MainActor.run {
                self.dailyCaffeine = samples
            }
        }
        .task {
            let samples = await HealthManager.shared.fetchNutritionalDailyQuantities(
                quantityTypeID: .dietaryFiber,
                unit: .gram(),
                numPrevDays: 30
            )
            await MainActor.run {
                self.dailyFiber = samples
            }
        }
        .task {
            let samples = (try? await HealthManager.shared.healthStore.fetchCollatedQuantity(
                quantityTypeID: .dietaryWater,
                unit: .literUnit(with: .milli),
                dateRange: .trailingMonthsFromNow(1)
            )) ?? []
            await MainActor.run {
                self.dailyWater = samples
            }
        }
        .onAppear {
            TelemetryDeck.viewScreen("Nutrition Vital Details")
        }
    }
}

private extension NutritionDetailsView {

    @ViewBuilder
    var netEnergyChart: some View {
        if let netEnergy = viewModel.nutritionSummary?.details.netEnergy {
            VStack(alignment: .leading, spacing: 16) {
                VitalDetailChartTitleView(
                    title: "Total Daily Energy Expendature",
                    valueLabel: "",
                    value: ""
                )

                Chart{
                    ForEach(dailyEnergy) { sample in
                        BarMark(
                            x: .value("Date", sample.date),
                            y: .value("Net Energy", sample.quantity)
                        )
                        .foregroundStyle((sample.quantity < 500 && sample.quantity > -500) ? .green : .yellow)
                        .cornerRadius(3)
                    }

                    RectangleMark(
                        yStart: .value("Max", 500),
                        yEnd: .value("Min", -500)
                    )
                    .foregroundStyle(.green.opacity(0.3))

                    RuleMark(
                        y: .value("Max", 500)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.green)

                    RuleMark(
                        y: .value("Min", -500)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.green)
                }
                .frame(height: 300)

                if let netEnergyDescription = viewModel.nutritionSummary?.details.netEnergyDescription {
                    HStack {
                        Text(netEnergyDescription)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var macrosChart: some View {
        if let details = viewModel.nutritionSummary?.details, let macros = details.macros {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Macros",
                    valueLabel: "",
                    value: details.macroStatus?.rawValue ?? ""
                )
                .padding(.horizontal)

                Divider()

                PillRangeChart(
                    title: "Protein",
                    quantityString: macros.protein.displayString(for: .gram()),
                    unitString: "%",
                    value: (macros.proteinPercent * 100),
                    minValue: HealthManager.shared.recommendedDailyProteinPercentOfDietaryEnergy().lowerBound * 100,
                    maxValue: HealthManager.shared.recommendedDailyProteinPercentOfDietaryEnergy().upperBound * 100
                )
                .tint(.protein)

                Divider()

                PillRangeChart(
                    title: "Carbohydrates",
                    quantityString: macros.carbohydrates.displayString(for: .gram()),
                    unitString: "%",
                    value: (macros.carbsPercent * 100),
                    minValue: HealthManager.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy().lowerBound * 100,
                    maxValue: HealthManager.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy().upperBound * 100
                )
                .tint(.carbohydrates)

                Divider()

                PillRangeChart(
                    title: "Fat",
                    quantityString: macros.fat.displayString(for: .gram()),
                    unitString: "%",
                    value: (macros.fatPercent * 100),
                    minValue: HealthManager.shared.recommendedDailyFatPercentOfDietaryEnergy().lowerBound * 100,
                    maxValue: HealthManager.shared.recommendedDailyFatPercentOfDietaryEnergy().upperBound * 100
                )
                .tint(.fat)
            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    var vitaminsChart: some View {
        if let details = viewModel.nutritionSummary?.details, let _ = details.vitaminScore {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Vitamins",
                    valueLabel: "",
                    value: details.vitaminStatus ?? ""
                )

                Divider()

                if let vitaminA = details.averageVitaminA?.doubleValue(for: .gramUnit(with: .micro)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminA() {
                    CapsuleRangeChart(
                        title: "Vitamin A",
                        unitString: "mcg",
                        value: vitaminA,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .micro)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .micro))
                    )
                    .tint(.vitaminA)
                }
                if let vitaminB6 = details.averageVitaminB6?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminB6() {
                    CapsuleRangeChart(
                        title: "Vitamin B6",
                        unitString: "mg",
                        value: vitaminB6,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.vitaminB6)
                }
                if let vitaminB12 = details.averageVitaminB12?.doubleValue(for: .gramUnit(with: .micro)), let goal = HealthManager.shared.recommendedMinDailyIntakeForVitaminB12() {
                    CapsuleRangeChart(
                        title: "Vitamin B12",
                        unitString: "mcg",
                        value: vitaminB12,
                        minValue: goal.doubleValue(for: .gramUnit(with: .micro)),
                        maxValue: 2000
                    )
                    .tint(.vitaminB12)
                }
                if let vitaminC = details.averageVitaminC?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminC() {
                    CapsuleRangeChart(
                        title: "Vitamin C",
                        unitString: "mg",
                        value: vitaminC,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.vitaminC)
                }
                if let vitaminD = details.averageVitaminD?.doubleValue(for: .gramUnit(with: .micro)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminD() {
                    CapsuleRangeChart(
                        title: "Vitamin D",
                        unitString: "mcg",
                        value: vitaminD,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .micro)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .micro))
                    )
                    .tint(.vitaminD)
                }
                if let vitaminE = details.averageVitaminE?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminE() {
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
        if let details = viewModel.nutritionSummary?.details, let _ = details.mineralScore {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Minerals",
                    valueLabel: "",
                    value: details.mineralStatus ?? ""
                )

                Divider()

                if let calcium = details.averageCalcium?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedIntakeForCalcium() {
                    CapsuleRangeChart(
                        title: "Calcium",
                        unitString: "mg",
                        value: calcium,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.calcium)
                }
                if let iron = details.averageIron?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForIron() {
                    CapsuleRangeChart(
                        title: "Iron",
                        unitString: "mg",
                        value: iron,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.iron)
                }
                if let magnesium = details.averageMagnesium?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForMagnesium() {
                    CapsuleRangeChart(
                        title: "Magnesium",
                        unitString: "mg",
                        value: magnesium,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.magnesium)
                }
                if let potassium = details.averagePotassium?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForPotassium() {
                    CapsuleRangeChart(
                        title: "Potassium",
                        unitString: "mg",
                        value: potassium,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.potassium)
                }
                if let sodium = details.averageSodium?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForSodium() {
                    CapsuleRangeChart(
                        title: "Sodium",
                        unitString: "mg",
                        value: sodium,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.sodium)
                }
                if let zinc = details.averageZinc?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForZinc() {
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
        if let details = viewModel.nutritionSummary?.details, let averageFiber = details.averageFiber {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Fiber",
                    value: averageFiber.displayString(for: .gram())
                )

                switch fiberChartScope {
                case .monthlyAverage:
                    Chart {
                        BarMark(
                            x: .value("Average Fiber", averageFiber.doubleValue(for: .gram()))
                        )
                        .foregroundStyle(.fiber)
                        .cornerRadius(10)

                        if let goal = HealthManager.shared.recommendedMinDailyIntakeForFiber() {
                            RuleMark(
                                x: .value("Min Fiber", goal.doubleValue(for: .gram()))
                            )
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundStyle(.text)
                        }
                    }
                    .chartXScale(
                        domain: 0...(max(averageFiber.doubleValue(for: .gram()), HealthManager.shared.recommendedMinDailyIntakeForFiber()?.doubleValue(for: .gram()) ?? 0) * 1.1),
                        range: .plotDimension
                    )
                    .frame(height: 60)
                case .daily:
                    Chart{
                        ForEach(dailyFiber) { sample in
                            BarMark(
                                x: .value("Date", sample.date),
                                y: .value("Daily Fiber", sample.quantity)
                            )
                            .foregroundStyle(.fiber)
                        }

                        if let goal = HealthManager.shared.recommendedMinDailyIntakeForFiber() {
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
                    }
                    .frame(height: 160)
                }

                Picker("", selection: $fiberChartScope) {
                    Text("Daily")
                        .tag(EnergyChartScope.daily)

                    Text("Monthly Average")
                        .tag(EnergyChartScope.monthlyAverage)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    @ViewBuilder
    var sugarChart: some View {
        if let details = viewModel.nutritionSummary?.details, let averageSugar = details.averageSugar {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Sugar",
                    value: averageSugar.displayString(for: .gram())
                )

                switch sugarChartScope {
                case .monthlyAverage:
                    Chart {
                        BarMark(
                            x: .value("Average Sugar", averageSugar.doubleValue(for: .gram()))
                        )
                        .foregroundStyle(.sugar)
                        .cornerRadius(10)

                        if let goal = HealthManager.shared.recommendedMaxDailyIntakeForSugar() {
                            RuleMark(
                                x: .value("Max Sugar", goal.doubleValue(for: .gram()))
                            )
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundStyle(.text)
                        }
                    }
                    .chartXScale(
                        domain: 0...(max(averageSugar.doubleValue(for: .gram()), HealthManager.shared.recommendedMaxDailyIntakeForSugar()?.doubleValue(for: .gram()) ?? 0) * 1.1),
                        range: .plotDimension
                    )
                    .frame(height: 60)
                case .daily:
                    Chart{
                        ForEach(dailySugar) { sample in
                            BarMark(
                                x: .value("Date", sample.date),
                                y: .value("Daily Sugar", sample.quantity)
                            )
                            .foregroundStyle(.sugar)
                        }

                        if let goal = HealthManager.shared.recommendedMaxDailyIntakeForSugar() {
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
                    }
                    .frame(height: 160)
                }

                Picker("", selection: $sugarChartScope) {
                    Text("Daily")
                        .tag(EnergyChartScope.daily)

                    Text("Monthly Average")
                        .tag(EnergyChartScope.monthlyAverage)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    @ViewBuilder
    var waterChart: some View {
        if let details = viewModel.nutritionSummary?.details, let averageWater = details.averageWater {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Water",
                    value: averageWater.displayString(for: .literUnit(with: .milli))
                )

                switch waterChartScope {
                case .monthlyAverage:
                    Chart {
                        BarMark(
                            x: .value("Average Water", averageWater.doubleValue(for: .literUnit(with: .milli)))
                        )
                        .foregroundStyle(.blue)
                        .cornerRadius(10)

                        RuleMark(
                            x: .value("Min Water Intake", 2000)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.text)
                    }
                    .chartXScale(
                        domain: 0...(max(averageWater.doubleValue(for: .literUnit(with: .milli)), 2000) * 1.1),
                        range: .plotDimension
                    )
                    .frame(height: 60)
                case .daily:
                    Chart{
                        ForEach(dailyWater) { sample in
                            BarMark(
                                x: .value("Date", sample.date),
                                y: .value("Water", sample.quantity.doubleValue(for: .literUnit(with: .milli)))
                            )
                            .foregroundStyle(.blue)
                        }

                        RuleMark(
                            y: .value("Min Water", 2000)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.blue)

                        RectangleMark(
                            yStart: .value("Min Water", 2000),
                            yEnd: .value("Min Water", 4000)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [.blue.opacity(0.3), .clear], startPoint: .bottom, endPoint: .top)
                        )
                    }
                    .frame(height: 160)
                }

                Picker("", selection: $waterChartScope) {
                    Text("Daily")
                        .tag(EnergyChartScope.daily)

                    Text("Monthly Average")
                        .tag(EnergyChartScope.monthlyAverage)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    @ViewBuilder
    var caffeineChart: some View {
        if let details = viewModel.nutritionSummary?.details, let averageCaffeine = details.averageCaffeine {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Caffeine",
                    value: averageCaffeine.displayString(for: .gramUnit(with: .milli))
                )

                switch caffeineChartScope {
                case .monthlyAverage:
                    Chart {
                        BarMark(
                            x: .value("Average Caffeine", averageCaffeine.doubleValue(for: .gramUnit(with: .milli)))
                        )
                        .foregroundStyle(.caffeine)
                        .cornerRadius(10)

                        if let goal = HealthManager.shared.recommendedMaxDailyCaffeine() {
                            RuleMark(
                                x: .value("Max Caffeine", goal.doubleValue(for: .gramUnit(with: .milli)))
                            )
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundStyle(.text)
                        }
                    }
                    .chartXScale(
                        domain: 0...(max(averageCaffeine.doubleValue(for: .gramUnit(with: .milli)), HealthManager.shared.recommendedMaxDailyCaffeine()?.doubleValue(for: .gramUnit(with: .milli)) ?? 0) * 1.1),
                        range: .plotDimension
                    )
                    .frame(height: 60)
                case .daily:
                    Chart{
                        ForEach(dailyCaffeine) { sample in
                            BarMark(
                                x: .value("Date", sample.date),
                                y: .value("Daily Caffeine", sample.quantity)
                            )
                            .foregroundStyle(.caffeine)
                        }

                        if let goal = HealthManager.shared.recommendedMaxDailyCaffeine() {
                            RuleMark(
                                y: .value("Max Caffeine", goal.doubleValue(for: .gramUnit(with: .milli)))
                            )
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundStyle(.caffeine)

                            RectangleMark(
                                yStart: .value("", 0),
                                yEnd: .value("Max Caffeine", goal.doubleValue(for: .gramUnit(with: .milli)))
                            )
                            .foregroundStyle(.caffeine.opacity(0.3))
                        }
                    }
                    .frame(height: 160)
                }

                Picker("", selection: $caffeineChartScope) {
                    Text("Daily")
                        .tag(EnergyChartScope.daily)

                    Text("Monthly Average")
                        .tag(EnergyChartScope.monthlyAverage)
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NutritionDetailsView()
    }
}
