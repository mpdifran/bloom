//
//  BodyWeightStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI
import Charts
import CoreHealth
import HealthKit

struct BodyWeightStatCard: View {
  let chartData: BodyWeightChartData?

  @State private var formattedWeight: String?

  var body: some View {
    StatCard(
      symbol: .gaugeWithDotsNeedle67percent,
      title: "Body Weight",
      value: formattedWeight ?? String(localized: "No Data", comment: "Stat card value shown when there is no data"),
      valueStyle: .largeTinted(relativeDate),
      layerContent: hasData,
      includePadding: !hasData
    ) {
      areaChart
    }
    .tint(chartData == nil ? .gray : .mutedIndigo)
    .task(id: chartData?.latestWeight) {
      formattedWeight = chartData?.latestWeight?.displayString(
        for: .pound(),
        formatter: .oneDecimalPlace
      )
    }
  }
}

private extension BodyWeightStatCard {

  var hasData: Bool {
    chartData?.dataPoints.isNotEmpty == true
  }

  var relativeDate: String? {
    guard let date = chartData?.latestDate else { return nil }
    let calendar = Calendar.current

    if calendar.isDateInToday(date) {
      return String(localized: "Today", comment: "Body weight card date label for a reading taken today")
    } else if calendar.isDateInYesterday(date) {
      return String(localized: "Yesterday", comment: "Body weight card date label for a reading taken yesterday")
    } else {
      let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
      return String(localized: "\(days) days ago", comment: "Body weight card date label. The placeholder is a number of days.")
    }
  }

  @ViewBuilder
  var areaChart: some View {
    if let dataPoints = chartData?.dataPoints, dataPoints.isNotEmpty {
      Chart(dataPoints) { dataPoint in
        AreaMark(
          x: .value("Date", dataPoint.date),
          y: .value("Weight", dataPoint.weight)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(.mutedIndigo.opacity(0.5))

        LineMark(
          x: .value("Date", dataPoint.date),
          y: .value("Weight", dataPoint.weight)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(.mutedIndigo)
        .lineStyle(StrokeStyle(lineWidth: 2))
      }
      .chartXAxis(.hidden)
      .chartYAxis(.hidden)
      .chartYScale(domain: chartYDomain)
      .padding(.top, 20)
    }
  }

  var chartYDomain: ClosedRange<Double> {
    guard let dataPoints = chartData?.dataPoints, dataPoints.isNotEmpty else {
      return 0...100
    }

    let weights = dataPoints.map(\.weight)
    let minWeight = weights.min() ?? 0
    let maxWeight = weights.max() ?? 100
    let padding = (maxWeight - minWeight) * 0.1

    return 0...(maxWeight + padding)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        BodyWeightStatCard(
          chartData: BodyWeightChartData(
            dataPoints: [
              BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 6), weight: 185),
              BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 5), weight: 184.5),
              BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 4), weight: 184.2),
              BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 3), weight: 183.8),
              BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 2), weight: 183.5),
              BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 1), weight: 183.2),
              BodyWeightDataPoint(date: Date(), weight: 182.7)
            ],
            latestWeight: HKQuantity(unit: .pound(), doubleValue: 182.7),
            latestDate: Date()
          )
        )

        BodyWeightStatCard(chartData: nil)
      }

      HStack {
        BodyWeightStatCard(
          chartData: BodyWeightChartData(
            dataPoints: [
              BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 3), weight: 75.2),
              BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 1), weight: 75.0)
            ],
            latestWeight: HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: 75.0),
            latestDate: Date().addingTimeInterval(-86400 * 1)
          )
        )

        BodyWeightStatCard(
          chartData: BodyWeightChartData(
            dataPoints: [
              BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 5), weight: 150)
            ],
            latestWeight: HKQuantity(unit: .pound(), doubleValue: 150),
            latestDate: Date().addingTimeInterval(-86400 * 5)
          )
        )
      }
    }
  }
}
