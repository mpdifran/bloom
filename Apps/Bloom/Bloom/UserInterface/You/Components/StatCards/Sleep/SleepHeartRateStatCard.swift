//
//  SleepHeartRateStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import SwiftUI
import Charts

struct SleepHeartRateStatCard: View {
  let heartRate: Double?
  let chartData: [SleepHeartRateDataPoint]?

  private var formattedHeartRate: String? {
    guard let heartRate else { return nil }
    return "\(Int(heartRate)) bpm"
  }

  private var hasChartData: Bool {
    chartData?.isNotEmpty ?? false
  }

  var body: some View {
    StatCard(
      symbol: .heartFill,
      title: "Sleep HR",
      value: formattedHeartRate ?? "No Data",
      valueStyle: .largeTinted(nil)
    ) {
      heartRateChart
    }
    .tint(heartRate == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.mutedRed))
  }
}

private extension SleepHeartRateStatCard {

  @ViewBuilder
  var heartRateChart: some View {
    if let dataPoints = chartData, dataPoints.isNotEmpty {
      Chart(dataPoints) { dataPoint in
        LineMark(
          x: .value("Day", dataPoint.date),
          y: .value("HR", dataPoint.heartRate)
        )
        .foregroundStyle(Color.mutedRed)
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2))

        PointMark(
          x: .value("Day", dataPoint.date),
          y: .value("HR", dataPoint.heartRate)
        )
        .foregroundStyle(Color(.systemBackground))
        .symbolSize(60)

        PointMark(
          x: .value("Day", dataPoint.date),
          y: .value("HR", dataPoint.heartRate)
        )
        .foregroundStyle(Color.mutedRed)
        .symbolSize(30)
      }
      .chartXAxis(.hidden)
      .chartYAxis(.hidden)
      .chartXScale(domain: chartXDomain)
      .chartYScale(domain: chartYDomain)
    }
  }

  var chartXDomain: ClosedRange<Date> {
    guard let dataPoints = chartData,
          let minDate = dataPoints.map(\.date).min(),
          let maxDate = dataPoints.map(\.date).max() else {
      return Date()...Date()
    }
    return minDate...maxDate
  }

  var chartYDomain: ClosedRange<Double> {
    guard let dataPoints = chartData,
          let minHR = dataPoints.map(\.heartRate).min(),
          let maxHR = dataPoints.map(\.heartRate).max() else {
      return 40...100
    }
    let padding = max((maxHR - minHR) * 0.2, 10)
    return (minHR - padding)...(maxHR + padding)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        SleepHeartRateStatCard(heartRate: 58, chartData: previewHeartRateData)
        SleepHeartRateStatCard(heartRate: nil, chartData: nil)
      }
    }
  }
}

private let previewHeartRateData: [SleepHeartRateDataPoint] = {
  let calendar = Calendar.current
  return (0..<7).reversed().compactMap { daysAgo -> SleepHeartRateDataPoint? in
    guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { return nil }
    return SleepHeartRateDataPoint(
      date: calendar.startOfDay(for: date),
      heartRate: Double.random(in: 52...65)
    )
  }
}()
