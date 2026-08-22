//
//  RestingHeartRateStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI
import Charts

struct RestingHeartRateStatCard: View {
  let restingHeartRate: Double?
  let chartData: [RestingHeartRateDataPoint]?

  var body: some View {
    StatCard(
      symbol: .heartFill,
      title: "Resting HR",
      value: formattedValue,
      valueStyle: .largeTinted(String(localized: "7 day avg", comment: "Stat card subtitle: the value is a seven day average"))
    ) {
      heartRateChart
    }
    .tint(restingHeartRate == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.mutedRed))
  }
}

private extension RestingHeartRateStatCard {

  var formattedValue: String {
    guard let restingHeartRate else { return String(localized: "No Data", comment: "Stat card value shown when there is no data") }
    return "\(Int(restingHeartRate)) bpm"
  }

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
        .symbol {
          Circle()
            .strokeBorder(Color.mutedRed, lineWidth: 2)
            .background(Circle().fill(.background))
            .frame(width: 8, height: 8)
        }
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
        RestingHeartRateStatCard(restingHeartRate: 62, chartData: previewRestingHeartRateData)
        RestingHeartRateStatCard(restingHeartRate: nil, chartData: nil)
      }
    }
  }
}

private let previewRestingHeartRateData: [RestingHeartRateDataPoint] = {
  let calendar = Calendar.current
  return (0..<7).reversed().compactMap { daysAgo -> RestingHeartRateDataPoint? in
    guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { return nil }
    return RestingHeartRateDataPoint(
      date: calendar.startOfDay(for: date),
      heartRate: Double.random(in: 58...68)
    )
  }
}()
