//
//  HRVDetailsView.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import SwiftUI
import Charts
import TelemetryDeck
import CoreHealth

struct HRVDetailsView: View {

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var hrvData: HRVDetailData?

  var body: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod, includeOneDay: true)

      if hrvData != nil {
        hrvChartSection

        averageComparisonSection

        DetailInfoCardView {
          Text("Heart Rate Variability (HRV) measures the variation in time between heartbeats. Higher HRV generally indicates better cardiovascular fitness and recovery, while lower HRV may suggest stress or fatigue.")
        }

        timeOfDaySection
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Heart Rate Variability",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("HRV")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: hrvData?.dataPoints.map(\.id))
    .task(id: selectedPeriod) {
      await loadData()
    }
    .onAppear {
      TelemetryDeck.viewScreen("HRV Details")
    }
  }
}

private extension HRVDetailsView {

  func loadData() async {
    hrvData = await YouStatsCalculator.shared.calculateHRVForPeriod(selectedPeriod)
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Data Available",
      systemImage: "waveform.path.ecg",
      description: Text("HRV is measured during sleep or rest periods with your Apple Watch.")
    )
  }

  // MARK: - HRV Chart Section

  @ViewBuilder
  var hrvChartSection: some View {
    if let hrvData {
      VStack(alignment: .leading) {
        VStack {
          VitalDetailChartTitleView(
            title: "Heart Rate Variability",
            value: "\(Int(hrvData.periodAverage)) ms"
          )

          hrvChart
            .frame(height: 250)
        }
        .cardContainer()
      }
    }
  }

  @ViewBuilder
  var hrvChart: some View {
    if let hrvData {
      Chart {
        ForEach(hrvData.dataPoints) { sample in
          LineMark(
            x: .value("Date", sample.date),
            y: .value("HRV", sample.quantity.doubleValue(for: .secondUnit(with: .milli)))
          )
          .foregroundStyle(Color.mutedTeal)
          .lineStyle(StrokeStyle(lineWidth: 3))
          .interpolationMethod(.catmullRom)
        }

        // Point marks with background
        ForEach(hrvData.dataPoints) { sample in
          PointMark(
            x: .value("Date", sample.date),
            y: .value("HRV", sample.quantity.doubleValue(for: .secondUnit(with: .milli)))
          )
          .foregroundStyle(Color(.systemBackground))
          .symbolSize(60)
        }

        ForEach(hrvData.dataPoints) { sample in
          PointMark(
            x: .value("Date", sample.date),
            y: .value("HRV", sample.quantity.doubleValue(for: .secondUnit(with: .milli)))
          )
          .foregroundStyle(Color.mutedTeal)
          .symbolSize(30)
        }

        // Average line
        RuleMark(y: .value("Average", hrvData.periodAverage))
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(Color.mutedTeal.opacity(0.5))
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
            if let hrv = value.as(Double.self) {
              Text(verbatim: "\(Int(hrv))")
            }
          }
        }
      }
    }
  }

  // MARK: - Average Comparison Section

  @ViewBuilder
  var averageComparisonSection: some View {
    if let hrvData,
       let sevenDay = hrvData.sevenDayAverage,
       let thirtyDay = hrvData.thirtyDayAverage {
      VStack {
        VitalDetailChartTitleView(
          title: "Trend",
          value: hrvData.trendText ?? "—"
        )

        HStack(spacing: 20) {
          VStack {
            Text(verbatim: "\(Int(sevenDay))")
              .font(.largeTitle)
              .bold()
              .fontDesign(.rounded)
            Text("7-Day Avg")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)

          Divider()
            .frame(height: 40)

          VStack {
            Text(verbatim: "\(Int(thirtyDay))")
              .font(.largeTitle)
              .bold()
              .fontDesign(.rounded)
            Text("30-Day Avg")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)

        trendIndicator
      }
      .cardContainer()
    }
  }

  @ViewBuilder
  var trendIndicator: some View {
    if let hrvData, let trend = hrvData.trend {
      HStack {
        Image(systemName: trendIconName(for: trend))
          .foregroundStyle(trendColor(for: trend))

        Text(trendDescription(for: trend))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.top, 4)
    }
  }

  func trendIconName(for trend: HRVChartData.Trend) -> String {
    switch trend {
    case .higher: "arrow.up.right"
    case .lower: "arrow.down.right"
    case .consistent: "arrow.right"
    }
  }

  func trendColor(for trend: HRVChartData.Trend) -> Color {
    switch trend {
    case .higher: .mutedGreen
    case .lower: .mutedOrange
    case .consistent: .secondary
    }
  }

  func trendDescription(for trend: HRVChartData.Trend) -> String {
    switch trend {
    case .higher: "Your HRV is trending higher, which may indicate improved recovery."
    case .lower: "Your HRV is trending lower. Consider prioritizing rest and recovery."
    case .consistent: "Your HRV has been consistent over the past month."
    }
  }

  // MARK: - Time of Day Section

  @ViewBuilder
  var timeOfDaySection: some View {
    if let hrvData, let timeOfDayPoints = hrvData.timeOfDayDataPoints, timeOfDayPoints.isNotEmpty {
      VStack(alignment: .leading) {
        VStack {
          VitalDetailChartTitleView(
            title: "By Time of Day",
            value: ""
          )

          timeOfDayChart(dataPoints: timeOfDayPoints)
            .frame(height: 180)
        }
        .cardContainer()

        DetailInfoCardView {
          Text("This chart shows your average HRV for each time of day over the selected period. HRV is typically higher during sleep and lower during active periods.")
        }
      }
    }
  }

  func timeOfDayChart(dataPoints: [HRVTimeOfDayDataPoint]) -> some View {
    Chart(dataPoints) { dataPoint in
      LineMark(
        x: .value("Hour", dataPoint.hourWindow),
        y: .value("HRV", dataPoint.averageHRV)
      )
      .foregroundStyle(Color.mutedTeal)
      .lineStyle(StrokeStyle(lineWidth: 3))
      .interpolationMethod(.catmullRom)

      PointMark(
        x: .value("Hour", dataPoint.hourWindow),
        y: .value("HRV", dataPoint.averageHRV)
      )
      .foregroundStyle(Color(.systemBackground))
      .symbolSize(60)

      PointMark(
        x: .value("Hour", dataPoint.hourWindow),
        y: .value("HRV", dataPoint.averageHRV)
      )
      .foregroundStyle(Color.mutedTeal)
      .symbolSize(30)
    }
    .chartXAxis {
      AxisMarks(values: [0, 6, 12, 18, 24]) { value in
        AxisGridLine()
        AxisValueLabel {
          if let hour = value.as(Double.self) {
            Text(hourLabel(for: Int(hour)))
              .font(.caption2)
          }
        }
      }
    }
    .chartYAxis {
      AxisMarks(position: .leading) { value in
        AxisGridLine()
        AxisValueLabel {
          if let hrv = value.as(Double.self) {
            Text(verbatim: "\(Int(hrv))")
          }
        }
      }
    }
    .chartXScale(domain: 0...24)
  }

  func hourLabel(for hour: Int) -> String {
    switch hour {
    case 0: "12am"
    case 6: "6am"
    case 12: "12pm"
    case 18: "6pm"
    case 24: "12am"
    default: ""
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      HRVDetailsView()
    }
  }
}
