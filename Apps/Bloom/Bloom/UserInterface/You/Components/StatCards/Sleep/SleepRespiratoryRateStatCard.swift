//
//  SleepRespiratoryRateStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import SwiftUI
import Charts

struct SleepRespiratoryRateStatCard: View {
  let trend: RespiratoryRateTrend?
  let chartData: [RespiratoryRateDataPoint]?

  private var hasChartData: Bool {
    chartData?.count ?? 0 >= 2
  }

  var body: some View {
    StatCard(
      symbol: .lungsFill,
      title: "Respiratory Rate",
      value: trend?.displayText ?? String(localized: "No Data", comment: "Stat card value shown when there is no data"),
      layerContent: true,
      includePadding: false
    ) {
      respiratoryRateChart
    }
    .tint(trend == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.mutedLightBlue))
  }
}

private extension SleepRespiratoryRateStatCard {

  @ViewBuilder
  var respiratoryRateChart: some View {
    if let chartData, chartData.count >= 2 {
      Chart {
        ForEach(chartData) { dataPoint in
          AreaMark(
            x: .value("Day", dataPoint.date),
            yStart: .value("Bottom", chartYDomain.lowerBound),
            yEnd: .value("Rate", dataPoint.rate)
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.mutedLightBlue.gradient)
        }

        if let lastPoint = chartData.last {
          PointMark(
            x: .value("Day", lastPoint.date),
            y: .value("Rate", lastPoint.rate)
          )
          .opacity(0)
          .annotation(position: .bottomLeading) {
            HStack(spacing: 4) {
              Text("\(Int(lastPoint.rate.rounded()))")
                .font(.subheadline)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(.white)
              Capsule()
                .fill(.white)
                .frame(width: 8, height: 2)
            }
          }
        }
      }
      .chartXAxis(.hidden)
      .chartYAxis(.hidden)
      .chartXScale(domain: chartXDomain)
      .chartYScale(domain: chartYDomain)
    } else {
      Rectangle()
        .fill(.gray)
        .padding(.top, 20)
    }
  }

  var chartXDomain: ClosedRange<Date> {
    guard let chartData,
          let minDate = chartData.map(\.date).min(),
          let maxDate = chartData.map(\.date).max() else {
      return Date()...Date()
    }
    return minDate...maxDate
  }

  var chartYDomain: ClosedRange<Double> {
    guard let chartData,
          let minRate = chartData.map(\.rate).min(),
          let maxRate = chartData.map(\.rate).max() else {
      return 0...20
    }
    return 0...maxRate
  }
}

#Preview {
  let calendar = Calendar.current

  PreviewEnvironment {
    BloomScrollView {
      HStack {
        SleepRespiratoryRateStatCard(
          trend: .consistent,
          chartData: (0..<7).reversed().compactMap { daysAgo -> RespiratoryRateDataPoint? in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { return nil }
            return RespiratoryRateDataPoint(
              date: calendar.startOfDay(for: date),
              rate: Double.random(in: 14...16)
            )
          }
        )
        SleepRespiratoryRateStatCard(trend: nil, chartData: nil)
      }
    }
  }
}
