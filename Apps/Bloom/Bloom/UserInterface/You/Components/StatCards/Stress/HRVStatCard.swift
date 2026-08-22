//
//  HRVStatCard.swift
//  Bloom
//
//  Created by Assistant on 2024-12-31.
//

import SwiftUI
import Charts

struct HRVStatCard: View {
  let data: HRVChartData?

  private var formattedHRV: String? {
    guard let data else { return nil }
    return "\(Int(data.sevenDayAverage)) ms"
  }

  private var hasChartData: Bool {
    data?.timeOfDayDataPoints.isNotEmpty ?? false
  }

  private var statCardTrend: StatCardTrend? {
    guard let trend = data?.trend else { return nil }
    switch trend {
    case .higher: return .trendingUp
    case .lower: return .trendingDown
    case .consistent: return .constant
    }
  }

  var body: some View {
    StatCard(
      symbol: .waveformPathEcg,
      title: "HRV",
      value: formattedHRV ?? String(localized: "No Data", comment: "Stat card value shown when there is no data"),
      valueStyle: .largeTinted(data?.trendText),
      trend: statCardTrend
    ) {
      hrvChart
    }
    .tint(data == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.teal))
  }
}

private extension HRVStatCard {

  @ViewBuilder
  var hrvChart: some View {
    if let dataPoints = data?.timeOfDayDataPoints, dataPoints.isNotEmpty {
      VStack(alignment: .leading, spacing: 0) {
        Text("Typical Day")
          .font(.caption2)
          .foregroundStyle(.secondary)

        Chart(dataPoints) { dataPoint in
          LineMark(
            x: .value("Hour", dataPoint.hourWindow),
            y: .value("HRV", dataPoint.averageHRV)
          )
          .foregroundStyle(Color.teal)
          .interpolationMethod(.catmullRom)
          .lineStyle(StrokeStyle(lineWidth: 2))

          PointMark(
            x: .value("Hour", dataPoint.hourWindow),
            y: .value("HRV", dataPoint.averageHRV)
          )
          .symbol {
            Circle()
              .strokeBorder(Color.teal, lineWidth: 2)
              .background(Circle().fill(.background))
              .frame(width: 8, height: 8)
          }
        }
        .chartXAxis {
          AxisMarks(values: [0, 6, 12, 18]) { value in
            AxisValueLabel {
              if let hour = value.as(Int.self) {
                Text(hourLabel(for: hour))
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
            }
          }
        }
        .chartYAxis(.hidden)
        .chartXScale(domain: chartXDomain)
        .chartYScale(domain: chartYDomain)
      }
    }
  }

  var chartXDomain: ClosedRange<Double> {
    // Always use full range so x-axis labels appear consistently
    0...24
  }

  var chartYDomain: ClosedRange<Double> {
    guard let dataPoints = data?.timeOfDayDataPoints,
          let minHRV = dataPoints.map(\.averageHRV).min(),
          let maxHRV = dataPoints.map(\.averageHRV).max() else {
      return 20...80
    }
    let padding = max((maxHRV - minHRV) * 0.2, 10)
    return (minHRV - padding)...(maxHRV + padding)
  }

  func hourLabel(for hour: Int) -> String {
    // Locale-aware: hardcoded "12a"/"6p" labels forced English 12-hour markers on 24-hour locales.
    guard let date = Calendar.current.date(from: DateComponents(hour: hour)) else { return "\(hour)" }
    return date.formatted(.dateTime.hour())
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        HRVStatCard(data: previewHRVData)
        HRVStatCard(data: nil)
      }
    }
  }
}

private let previewHRVData = HRVChartData(
  sevenDayAverage: 45,
  thirtyDayAverage: 42,
  timeOfDayDataPoints: [
    HRVTimeOfDayDataPoint(hourWindow: 1.5, averageHRV: 52),
    HRVTimeOfDayDataPoint(hourWindow: 4.5, averageHRV: 50),
    HRVTimeOfDayDataPoint(hourWindow: 7.5, averageHRV: 42),
    HRVTimeOfDayDataPoint(hourWindow: 10.5, averageHRV: 38),
    HRVTimeOfDayDataPoint(hourWindow: 13.5, averageHRV: 35),
    HRVTimeOfDayDataPoint(hourWindow: 16.5, averageHRV: 38),
    HRVTimeOfDayDataPoint(hourWindow: 19.5, averageHRV: 45),
    HRVTimeOfDayDataPoint(hourWindow: 22.5, averageHRV: 50)
  ]
)
