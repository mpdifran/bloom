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
import CoreHealth

struct HeartHealthDetailsView: View {

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var restingHeartRateSamples = [DateQuantitySample]()
  @State private var heartRateReserveData: HeartRateReserveDetailData?
  @State private var heartRateRecoveryData: HeartRateRecoveryDetailData?

  var body: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)

      if hasData {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Heart Health",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Heart Health")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: restingHeartRateSamples.map(\.id))
    .animation(.default, value: heartRateReserveData?.dataPoints.map(\.id))
    .animation(.default, value: heartRateRecoveryData?.currentPeriodAverage)
    .task(id: selectedPeriod) {
      await loadData()
    }
    .onAppear {
      TelemetryDeck.viewScreen("Heart Health Details")
    }
  }
}

private extension HeartHealthDetailsView {

  var hasData: Bool {
    restingHeartRateSamples.isNotEmpty || heartRateReserveData != nil || heartRateRecoveryData != nil
  }

  func loadData() async {
    let interval = selectedPeriod.aggregatesByWeek ? DateComponents(weekOfYear: 1) : DateComponents(day: 1)

    async let rhrSamples = HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .restingHeartRate,
      unit: .bpm(),
      interval: interval,
      dateRange: selectedPeriod.dateRange
    )
    async let hrrData = YouStatsCalculator.shared.calculateHeartRateReserveForPeriod(selectedPeriod)
    async let recoveryData = YouStatsCalculator.shared.calculateHeartRateRecoveryForPeriod(selectedPeriod)

    let (rhr, hrr, recovery) = await (rhrSamples, hrrData, recoveryData)
    await MainActor.run {
      self.restingHeartRateSamples = rhr
      self.heartRateReserveData = hrr
      self.heartRateRecoveryData = recovery
    }
  }

  @ViewBuilder
  var contentView: some View {
    restingHeartRateChart
    heartRateReserveChart
    heartRateRecoveryChart
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Data Available",
      systemImage: "heart.fill",
      description: Text("Wear your Apple Watch throughout the day to get a better picture of your Heart Health.")
    )
  }

  // MARK: - Resting Heart Rate Chart

  @ViewBuilder
  var restingHeartRateChart: some View {
    if restingHeartRateSamples.isNotEmpty {
      VStack(alignment: .leading) {
        VStack {
          VitalDetailChartTitleView(
            title: "Resting Heart Rate",
            value: averageRestingHeartRateDisplay
          )

          Chart {
            ForEach(restingHeartRateSamples) { sample in
              LineMark(
                x: .value("Date", sample.date),
                y: .value("Resting Heart Rate", sample.quantity.doubleValue(for: .bpm()))
              )
              .foregroundStyle(.mutedRed)
              .lineStyle(StrokeStyle(lineWidth: 3))
              .interpolationMethod(.catmullRom)
            }

            ForEach(restingHeartRateSamples) { sample in
              PointMark(
                x: .value("Date", sample.date),
                y: .value("Resting Heart Rate", sample.quantity.doubleValue(for: .bpm()))
              )
              .foregroundStyle(Color(.systemBackground))
              .symbolSize(60)
            }

            ForEach(restingHeartRateSamples) { sample in
              PointMark(
                x: .value("Date", sample.date),
                y: .value("Resting Heart Rate", sample.quantity.doubleValue(for: .bpm()))
              )
              .foregroundStyle(.mutedRed)
              .symbolSize(30)
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
          .chartXAxis {
            AxisMarks(values: .automatic) { value in
              AxisGridLine()
              AxisValueLabel(format: selectedPeriod.chartDateFormat)
            }
          }
          .chartYAxis {
            AxisMarks(position: .leading) { value in
              AxisGridLine()
              AxisValueLabel {
                if let hr = value.as(Double.self) {
                  Text(verbatim: "\(Int(hr))")
                }
              }
            }
          }
          .chartYScale(
            domain: rhrChartMin...rhrChartMax,
            range: .plotDimension(padding: 10)
          )
          .frame(height: 200)
        }
        .cardContainer()

        if let restingHeartRateDescription {
          DetailInfoCardView {
            Text(restingHeartRateDescription)
          }
        }
      }
    }
  }

  var averageRestingHeartRateDisplay: String {
    guard restingHeartRateSamples.isNotEmpty else { return "" }
    let average = restingHeartRateSamples.map { $0.quantity.doubleValue(for: .bpm()) }.reduce(0, +) / Double(restingHeartRateSamples.count)
    return "\(Int(average)) bpm"
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
    guard restingHeartRateSamples.isNotEmpty else { return nil }

    let values = restingHeartRateSamples.map { $0.quantity.doubleValue(for: .bpm()) }
    let avgRHR = values.reduce(0, +) / Double(values.count)
    let goal = HealthGoalProvider.shared.goalRestingHeartRateForUser()

    if avgRHR < goal.1 {
      return "A low resting heart rate can be a good indicator of an efficient metabolism, can reduce your risk of heart disease, and help you live longer. For your age and sex, it is recommended your resting heart rate is below \(goal.1.format()) bpm."
    } else {
      return "A high resting heart rate can increase your risk of diabetes, stroke, and heart disease. For your age and sex, it is recommended your resting heart rate is below \(goal.1.format()) bpm."
    }
  }

  // MARK: - Heart Rate Reserve Chart

  @ViewBuilder
  var heartRateReserveChart: some View {
    if let heartRateReserveData, heartRateReserveData.dataPoints.isNotEmpty {
      VStack(alignment: .leading) {
        VStack {
          VitalDetailChartTitleView(
            title: "Heart Rate Reserve",
            value: "\(heartRateReserveData.averageHRR) bpm"
          )

          hrrChart
            .frame(height: 200)

          hrrLegend
        }
        .cardContainer()

        DetailInfoCardView {
          Text(heartRateReserveDescription)
        }
      }
    }
  }

  var hrrChart: some View {
    Chart(heartRateReserveData?.dataPoints ?? []) { dataPoint in
      // Area between resting HR (bottom) and max HR (top)
      AreaMark(
        x: .value("Date", dataPoint.date),
        yStart: .value("Resting", dataPoint.restingHeartRate),
        yEnd: .value("Max", dataPoint.maxHeartRate)
      )
      .foregroundStyle(
        LinearGradient(
          colors: [Color.mutedRed.opacity(0.3), Color.mutedRed.opacity(0.05)],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .interpolationMethod(.catmullRom)

      // Top line (max HR)
      LineMark(
        x: .value("Date", dataPoint.date),
        y: .value("HR", dataPoint.maxHeartRate),
        series: .value("Series", "Max HR")
      )
      .foregroundStyle(.mutedRed)
      .lineStyle(StrokeStyle(lineWidth: 3))
      .interpolationMethod(.catmullRom)

      // Bottom line (resting HR)
      LineMark(
        x: .value("Date", dataPoint.date),
        y: .value("HR", dataPoint.restingHeartRate),
        series: .value("Series", "Resting HR")
      )
      .foregroundStyle(.mutedRed.opacity(0.5))
      .lineStyle(StrokeStyle(lineWidth: 3))
      .interpolationMethod(.catmullRom)
    }
    .chartXAxis {
      AxisMarks(values: .automatic) { value in
        AxisGridLine()
        AxisValueLabel(format: selectedPeriod.chartDateFormat)
      }
    }
    .chartYAxis {
      AxisMarks(position: .leading) { value in
        AxisGridLine()
        AxisValueLabel {
          if let hr = value.as(Double.self) {
            Text(verbatim: "\(Int(hr))")
          }
        }
      }
    }
    .chartYScale(domain: hrrChartYDomain)
    .chartLegend(.hidden)
  }

  var hrrLegend: some View {
    HStack(spacing: 16) {
      HStack(spacing: 4) {
        Circle()
          .fill(Color.mutedRed)
          .frame(width: 8, height: 8)
        Text("Max HR")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      HStack(spacing: 4) {
        Circle()
          .fill(Color.mutedRed.opacity(0.5))
          .frame(width: 8, height: 8)
        Text("Resting HR")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  var hrrChartYDomain: ClosedRange<Double> {
    guard let data = heartRateReserveData?.dataPoints,
          let minResting = data.map(\.restingHeartRate).min(),
          let maxHR = data.map(\.maxHeartRate).max() else {
      return 40...200
    }

    let padding = (maxHR - minResting) * 0.1
    return (minResting - padding)...(maxHR + padding)
  }

  var heartRateReserveDescription: String {
    "Heart Rate Reserve (HRR) is the difference between your maximum heart rate and resting heart rate. A larger reserve indicates better cardiovascular fitness, as your heart can handle a wider range of intensities during exercise."
  }

  // MARK: - Heart Rate Recovery Chart

  @ViewBuilder
  var heartRateRecoveryChart: some View {
    if let heartRateRecoveryData,
       heartRateRecoveryData.currentPeriodAverage != nil || heartRateRecoveryData.previousPeriodAverage != nil {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Heart Rate Recovery",
          value: recoveryDisplayValue
        )

        Chart {
          RuleMark(x: .value("Min", Double.minHeartRateRecovery))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(.pink)

          RectangleMark(
            xStart: .value("Min", Double.minHeartRateRecovery),
            xEnd: .value("", recoveryMaxValue)
          )
          .foregroundStyle(
            LinearGradient(
              colors: [.pink.opacity(0.3), .pink.opacity(0.05)],
              startPoint: .leading,
              endPoint: .trailing
            )
          )

          if let previousAverage = heartRateRecoveryData.previousPeriodAverage {
            BarMark(
              x: .value("Heart Rate Recovery", previousAverage),
              y: .value("Time Period", selectedPeriod.previousPeriodLabel)
            )
            .foregroundStyle(.gray)
            .cornerRadius(10)
          }

          if let currentAverage = heartRateRecoveryData.currentPeriodAverage {
            BarMark(
              x: .value("Heart Rate Recovery", currentAverage),
              y: .value("Time Period", selectedPeriod.currentPeriodLabel)
            )
            .foregroundStyle(.pink)
            .cornerRadius(10)
          }
        }
        .chartYAxis {
          AxisMarks(values: [selectedPeriod.previousPeriodLabel, selectedPeriod.currentPeriodLabel]) {
            AxisGridLine()
            AxisTick()
            AxisValueLabel()
          }
        }
        .chartYScale(domain: [selectedPeriod.previousPeriodLabel, selectedPeriod.currentPeriodLabel])
        .chartXScale(domain: 0...recoveryMaxValue, range: .plotDimension)
        .frame(height: 150)
      }
      .cardContainer()
    }
  }

  var recoveryDisplayValue: String {
    guard let current = heartRateRecoveryData?.currentPeriodAverage else { return "" }
    return "\(Int(current)) bpm"
  }

  var recoveryMaxValue: Double {
    let maxDataPoint = max(
      heartRateRecoveryData?.currentPeriodAverage ?? 0,
      heartRateRecoveryData?.previousPeriodAverage ?? 0
    )
    return max(maxDataPoint * 1.1, 40)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationView {
      HeartHealthDetailsView()
    }
  }
}
