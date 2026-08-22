//
//  ActivityLevelDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-09.
//

import SwiftUI
import Charts
import TelemetryDeck
import CoreHealth

struct ActivityLevelDetailsView: View {

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var selectedActivityLevelIndex = 0
  @State private var activityLevelDetails: ActivityLevelSummary.Details?
  @State private var aggregatedEnergyRatios: [DateValueSample] = []
  @State private var workoutSummations = [WorkoutSummation]()

  var body: some View {
    Group {
      if activityLevelDetails?.hasNoData == false {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Activity Level",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Activity Level")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: selectedActivityLevelIndex)
    .animation(.default, value: aggregatedEnergyRatios.map(\.id))
    .animation(.default, value: workoutSummations.map(\.id))
    .task(id: selectedPeriod) {
      let dateRange = selectedPeriod.dateRange

      activityLevelDetails = await HealthStoreFetcher.shared.fetchActivityLevelSummaryDetails(dateRange: dateRange)
      workoutSummations = await HealthStoreFetcher.shared.fetchWorkoutSummations(dateRange: dateRange)
      aggregatedEnergyRatios = aggregateEnergyRatios()
    }
    .onChange(of: activityLevelDetails) {
      if let index = ActivityLevelSummary.ActivityLevel.allCases.firstIndex(where: { $0 == activityLevelDetails?.activityLevel }) {
        selectedActivityLevelIndex = index
      }
    }
    .onAppear {
      TelemetryDeck.viewScreen("Activity Level Vital Details")
    }
  }
}

private extension ActivityLevelDetailsView {

  var contentView: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)

      activityLevelRatioChart
      ratioDistributionView
      dayOfWeekDistributionView
      workoutSummationViews
    }
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Data Available",
      systemImage: "figure.tennis",
      description: Text("Wear your Apple Watch throughout the day to get a better picture of your Activity Level.")
    )
  }

  @ViewBuilder
  var activityLevelRatioChart: some View {
    if let activityLevelDetails {
      VStack(alignment: .leading) {
        VStack {
          VitalDetailChartTitleView(
            title: "Energy Ratio",
            value: activityLevelDetails.activityLevel?.name ?? "Unknown"
          )

          Chart {
            ForEach(aggregatedEnergyRatios) { ratio in
              BarMark(
                x: .value("Date", ratio.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
                yStart: .value("", 1),
                yEnd: .value("Ratio", ratio.value)
              )
              .foregroundStyle(color(for: ratio.value))
            }

            RectangleMark(
              yStart: .value("Min", selectedLevel.range.lowerBound),
              yEnd: .value("Max", min(selectedLevel.range.upperBound, chartMax))
            )
            .foregroundStyle(selectedLevel.color.opacity(0.3))

            RuleMark(y: .value("Min", selectedLevel.range.lowerBound))
              .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
              .foregroundStyle(selectedLevel.color)

            if selectedLevel.range.upperBound < chartMax {
              RuleMark(y: .value("Max", min(selectedLevel.range.upperBound, chartMax)))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(selectedLevel.color)
            }
          }
          .chartYScale(domain: 1...chartMax, range: .plotDimension(startPadding: 10, endPadding: 0))
          .frame(height: 300)
          .clipped()

          levelPicker
        }
        .cardContainer()

        DetailInfoCardView {
          Text("Energy Ratio is the ratio between your Basal Energy and TDEE (Total Daily Energy Exertion) for a given day. The higher the ratio, the more active you were.")

          HealthCitationLinkView(url: .faoHumanEnergyRequirements, title: "Based on Physical Activity Level (PAL) definitions from the FAO/WHO/UNU Expert Consultation on Human Energy Requirements (2001).")
        }
      }
    }
  }

  var chartMax: Double {
    guard let maxValue = aggregatedEnergyRatios.max(keyPath: \.value) else { return 2 }

    return max(maxValue * 1.1, 2)
  }

  func aggregateEnergyRatios() -> [DateValueSample] {
    guard let samples = activityLevelDetails?.energyRatioSamples else { return [] }

    if selectedPeriod.aggregatesByWeek {
      let calendar = Calendar.current
      var weeklyData = [Date: [Double]]()

      for sample in samples {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: sample.date)?.start ?? sample.date
        weeklyData[weekStart, default: []].append(sample.value)
      }

      return weeklyData.map { weekStart, values in
        DateValueSample(
          date: weekStart,
          value: values.reduce(0, +) / Double(values.count)
        )
      }.sorted { $0.date < $1.date }
    } else {
      return samples
    }
  }

  func color(for ratio: Double) -> Color {
    let activityLevel = ActivityLevelSummary.ActivityLevel(ratio)

    if activityLevel == selectedLevel {
      return selectedLevel.color
    }
    return .green.opacity(0.3)
  }

  var selectedLevel: ActivityLevelSummary.ActivityLevel {
    ActivityLevelSummary.ActivityLevel.allCases[selectedActivityLevelIndex]
  }

  var levelPicker: some View {
    Button {
      selectedActivityLevelIndex = (selectedActivityLevelIndex + 1) % ActivityLevelSummary.ActivityLevel.allCases.count
    } label: {
      HStack {
        Text("Level")

        Spacer()

        Text(selectedLevel.name)
      }
    }
    .buttonStyle(.zone)
    .tint(selectedLevel.color)
    .sensoryFeedback(.selection, trigger: selectedActivityLevelIndex)
  }

  var ratioDistributionView: some View {
    VStack {
      VitalDetailChartTitleView(title: "By Level", value: "")
      ActivityLevelDistributionView(ratioDistribution: activityLevelDetails?.activityLevelRatioDistribution ?? [:])
    }
    .cardContainer()
  }

  @ViewBuilder
  var dayOfWeekDistributionView: some View {
    if let distribution = activityLevelDetails?.dayOfWeekActivityLevelRatioDistribution() {
      VStack {
        VitalDetailChartTitleView(title: "Avg By Day of Week", value: "")

        Chart {
          ForEach(distribution.keys.sorted(keyPath: \.self), id: \.self) { dayOfWeek in
            BarMark(
              x: .value("Day", dayOfWeek.dayOfWeekLabel),
              yStart: .value("", 1),
              yEnd: .value("Average Activity Level", distribution[dayOfWeek, default: 1])
            )
            .cornerRadius(5)
            .foregroundStyle(ActivityLevelSummary.ActivityLevel(distribution[dayOfWeek, default: 1]).barColor)
          }
        }
        .chartYScale(domain: 1...((distribution.max(keyPath: \.value) ?? 1.8) * 1.1), range: .plotDimension)
        // Calendar symbols, not hardcoded English: the bar labels below are localized, so an
        // English domain would neither match them nor read correctly in other languages.
        .chartXScale(domain: Calendar.current.shortWeekdaySymbols, range: .plotDimension)
        .chartXAxis {
          AxisMarks(values: Calendar.current.shortWeekdaySymbols) { value in
            AxisGridLine()
            AxisTick()

            if let intValue = value.as(Int.self) {
              AxisValueLabel {
                Text(intValue.dayOfWeekLabel)
              }
            } else {
              AxisValueLabel()
            }
          }
        }
        .frame(height: 200)
      }
      .cardContainer()
    }
  }

  @ViewBuilder
  var workoutSummationViews: some View {
    if workoutSummations.isNotEmpty {
      VStack {
        VitalDetailChartTitleView(title: "Workouts", value: "")
          .padding(.horizontal)

        ForEach(workoutSummations) { workoutSummation in
          NavigationLink {
            WorkoutsListView(activityType: workoutSummation.activityType)
          } label: {
            WorkoutSummationCell(workoutSummation: workoutSummation)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}

private extension Int {

  /// Uses the calendar's own symbols rather than hardcoded English abbreviations, which
  /// rendered as "Sun"/"Mon" in every language.
  var dayOfWeekLabel: String {
    let symbols = Calendar.current.shortWeekdaySymbols
    guard (1...symbols.count).contains(self) else { return "" }
    return symbols[self - 1]
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ActivityLevelDetailsView()
    }
  }
}
