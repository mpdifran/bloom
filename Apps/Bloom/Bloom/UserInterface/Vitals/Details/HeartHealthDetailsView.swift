//
//  HeartHealthDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-11.
//

import SwiftUI
import Charts
import TelemetryDeck
import HealthKit

struct HeartHealthDetailsView: View {

  @State private var selectedFitnessLevelIndex: Int = 0
  @State private var vo2MaxSamples = [DateQuantitySample]()
  @State private var restingHeartRateSamples = [DateQuantitySample]()

  private let viewModel = VitalsViewModel.shared

  private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

  private let fitnessLevels: [HeartHealthMonthlySummary.CardioFitnessLevel] = [
    .low,
    .belowAverage,
    .aboveAverage,
    .high
  ]

  var body: some View {
    Group {
      if viewModel.heartHealthSummary?.details.hasNoData == false {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Heart Health",
          subtitle: "Last 30 Days"
        )
      }
    }
    .navigationTitle("Heart Health")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: selectedFitnessLevelIndex)
    .task {
      let samples = await HealthStoreFetcher.shared.fetchCollatedAverage(
        quantityType: .vo2Max,
        unit: .vo2Max(),
        dateRange: .trailingMonthsFromNow(1)
      )
      await MainActor.run {
        self.vo2MaxSamples = samples
      }
    }
    .task {
      let samples = await HealthStoreFetcher.shared.fetchCollatedAverage(
        quantityType: .restingHeartRate,
        unit: .bpm(),
        dateRange: .trailingMonthsFromNow(1)
      )
      await MainActor.run {
        self.restingHeartRateSamples = samples
      }
    }
    .onAppear {
      feedbackGenerator.prepare()
      if let level = viewModel.heartHealthSummary?.details.cardioFitnessLevel, let index = fitnessLevels.firstIndex(of: level) {
        self.selectedFitnessLevelIndex = index
      }
      TelemetryDeck.viewScreen("Heart Health Vital Details")
    }
  }
}

private extension HeartHealthDetailsView {

  var contentView: some View {
    ScrollView {
      vo2MaxChart
        .padding()

      restingHeartRateChart
        .padding()

      heartRateRecoveryChart
        .padding()
    }
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Data Available",
      systemImage: "heart.fill",
      description: Text("Wear your Apple Watch throughout the day to get a better picture of your Heart Health.")
    )
  }

  var fitnessLevel: HeartHealthMonthlySummary.CardioFitnessLevel {
    fitnessLevels[selectedFitnessLevelIndex]
  }

  var selectedFitnessLevelRanges: (Double, Double)? {
    guard let goal = HealthGoalProvider.shared.goalVO2MaxForUser() else { return nil }

    switch selectedFitnessLevelIndex {
    case 0:
      return (0, goal.2)
    case 1:
      return (goal.2, goal.1)
    case 2:
      return (goal.1, goal.0)
    case 3:
      return (goal.0, max((maxVO2Max ?? 0) * 1.1, 60))
    default:
      return nil
    }
  }

  var maxVO2Max: Double? {
    vo2MaxSamples.map({ $0.quantity.doubleValue(for: .vo2Max()) }).max(keyPath: \.self)
  }

  var minVO2Max: Double? {
    vo2MaxSamples.map({ $0.quantity.doubleValue(for: .vo2Max()) }).min(keyPath: \.self)
  }

  var chartMin: Double {
    let rangeMin = selectedFitnessLevelRanges?.0

    if let min = [rangeMin, minVO2Max].unwrap().min() {
      return min * 0.9
    }
    return 20
  }

  var chartMax: Double {
    let rangeMax = selectedFitnessLevelRanges?.1

    if let max = [rangeMax, maxVO2Max].unwrap().max() {
      return max * 1.1
    }
    return 50
  }

  var vo2MaxChart: some View {
    VStack(alignment: .leading) {
      VitalDetailChartTitleView(title: "VO₂ Max", value: viewModel.heartHealthSummary?.details.averageVO2Max?.displayString(for: .vo2Max()) ?? "")

      Group {
        if vo2MaxSamples.isEmpty {
          ContentUnavailableView(
            "No Data Available",
            systemImage: "heart.fill",
            description: Text("There are no VO₂ Max samples in the past month.")
          )
        } else {
          Chart {
            if let selectedFitnessLevelRanges {
              RectangleMark(
                yStart: .value("Min", selectedFitnessLevelRanges.0),
                yEnd: .value("Max", selectedFitnessLevelRanges.1)
              )
              .foregroundStyle(fitnessLevel.color.opacity(0.3))

              RuleMark(y: .value("Min", selectedFitnessLevelRanges.0))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(fitnessLevel.color)
              RuleMark(y: .value("Max", selectedFitnessLevelRanges.1))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(fitnessLevel.color)
            }

            ForEach(vo2MaxSamples) { sample in
              LineMark(
                x: .value("Date", sample.date),
                y: .value("VO₂ Max", sample.quantity.doubleValue(for: .vo2Max()))
              )
              .foregroundStyle(viewModel.heartHealthSummary?.details.cardioFitnessLevel?.color ?? .mutedPink)
              PointMark(
                x: .value("Date", sample.date),
                y: .value("VO₂ Max", sample.quantity.doubleValue(for: .vo2Max()))
              )
              .foregroundStyle(viewModel.heartHealthSummary?.details.cardioFitnessLevel?.color ?? .mutedPink)
            }
          }
          .chartYScale(domain: chartMin...chartMax, range: .plotDimension)
        }
      }
      .frame(height: 250)

      if vo2MaxSamples.isNotEmpty {
        Button {
          selectedFitnessLevelIndex = (selectedFitnessLevelIndex + 1) % fitnessLevels.count
          feedbackGenerator.impactOccurred()
        } label: {
          HStack {
            Text("Fitness Level")

            Spacer()

            Text(fitnessLevel.name)
          }
        }
        .buttonStyle(.zone)
        .tint(fitnessLevel.color)

        DetailInfoCardView {
          Text(fitnessLevel.summary)
          Text("Fitness levels derived from the Fitness Registry and Importance of Exercise National Database (FRIEND).")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  var heartRateRecoveryChart: some View {
    VStack(alignment: .leading) {
      VitalDetailChartTitleView(
        title: "Heart Rate Recovery",
        value: viewModel.heartHealthSummary?.details.displayHeartRateRecovery ?? ""
      )

      Chart {
        RuleMark(x: .value("Min", Double.minHeartRateRecovery))
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(.pink)

        RectangleMark(
          xStart: .value("Min", Double.minHeartRateRecovery),
          xEnd: .value("", maxValue)
        )
        .foregroundStyle(
          LinearGradient(
            colors: [.pink.opacity(0.3), .pink.opacity(0.05)],
            startPoint: .leading,
            endPoint: .trailing
          )
        )

        if let lastMonthHeartRateRecovery = viewModel.heartHealthSummary?.lastMonthDetails.averageHeartRateRecovery {
          BarMark(
            x: .value("Heart Rate Recovery", lastMonthHeartRateRecovery.doubleValue(for: .bpm())),
            y: .value("Time Peroid", "Last Month")
          )
          .foregroundStyle(.gray)
          .cornerRadius(10)
        }
        if let heartRateRecovery = viewModel.heartHealthSummary?.details.averageHeartRateRecovery {
          BarMark(
            x: .value("Heart Rate Recovery", heartRateRecovery.doubleValue(for: .bpm())),
            y: .value("Time Peroid", "This Month")
          )
          .foregroundStyle(.pink)
          .cornerRadius(10)
        }
      }
      .chartYAxis {
        AxisMarks(values: ["Last Month", "This Month"]) {
          AxisGridLine()
          AxisTick()
          AxisValueLabel()
        }
      }
      .chartYScale(domain: ["Last Month", "This Month"])
      .chartXScale(domain: 0...maxValue, range: .plotDimension)
      .frame(height: 150)
    }
  }

  var maxValue: Double {
    let maxDataPoint = max(
      viewModel.heartHealthSummary?.lastMonthDetails.averageHeartRateRecovery?.doubleValue(for: .bpm()) ?? 0,
      viewModel.heartHealthSummary?.details.averageHeartRateRecovery?.doubleValue(for: .bpm()) ?? 0
    )

    return max(maxDataPoint * 1.1, 40)
  }
}

private extension HeartHealthDetailsView {

  var restingHeartRateChart: some View {
    VStack(alignment: .leading) {
      VitalDetailChartTitleView(
        title: "Resting Heart Rate",
        value: viewModel.heartHealthSummary?.details.displayRestingHeartRate ?? ""
      )

      Chart {
        ForEach(restingHeartRateSamples) { sample in
          LineMark(
            x: .value("Date", sample.date),
            y: .value("Resting Heart Rate", sample.quantity.doubleValue(for: .bpm()))
          )
          .foregroundStyle(.mutedRed)
          .interpolationMethod(.catmullRom)
        }
        let goal = HealthGoalProvider.shared.goalRestingHeartRateForUser()

        RuleMark(y: .value("Max RHR", goal.1))
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(.mutedRed)

        RectangleMark(
          yStart: .value("", goal.1 - 20),
          yEnd: .value("Max RHR", goal.1)
        )
        .foregroundStyle(
          LinearGradient(
            colors: [
              .mutedRed.opacity(0.3),
              .clear
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
      }
      .chartYScale(
        domain: rhrChartMin...rhrChartMax,
        range: .plotDimension(padding: 10)
      )
      .frame(height: 160)

      if let restingHeartRateDescription {
        DetailInfoCardView {
          Text(restingHeartRateDescription)
        }
        .padding(.top)
      }
    }
  }

  var rhrChartMin: Double {
    let goal = HealthGoalProvider.shared.goalRestingHeartRateForUser()

    return min(minRestingHeartRate ?? 0, goal.1 - 20)
  }

  var rhrChartMax: Double {
    let goal = HealthGoalProvider.shared.goalRestingHeartRateForUser()

    return max(maxRestingHeartRate ?? 100, goal.1)
  }

  var minRestingHeartRate: Double? {
    restingHeartRateSamples.map({ $0.quantity.doubleValue(for: .bpm()) }).min()
  }

  var maxRestingHeartRate: Double? {
    restingHeartRateSamples.map({ $0.quantity.doubleValue(for: .bpm()) }).max()
  }

  var restingHeartRateDescription: String? {
    guard let restingHeartRate = viewModel.heartHealthSummary?.details.averageRestingHeartRate?.doubleValue(for: .bpm()) else {
      return nil
    }

    let goal = HealthGoalProvider.shared.goalRestingHeartRateForUser()

    if restingHeartRate < goal.1 {
      return "A low resting heart rate can be a good indicator of an efficient metabolism, can reduce your risk of heart disease, and help you live longer. For your age and sex, it is recommended your resting heart rate is below \(goal.1.format()) bpm."
    } else {
      return "A high resting heart rate can increase your risk of diabetes, stroke, and heart disease. For your age and sex, it is recommended your resting heart rate is below \(goal.1.format()) bpm."
    }
  }
}

#Preview {
  NavigationView {
    HeartHealthDetailsView()
  }
}
