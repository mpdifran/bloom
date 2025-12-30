//
//  MaxHeartRateStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI
import Charts

struct MaxHeartRateStatCard: View {
  let chartData: MaxHeartRateChartData?

  var body: some View {
    StatCard(
      symbol: .arrowUpHeartFill,
      title: "Max HR",
      value: hasData ? nil : "No Data",
      valueStyle: .largeTinted("7 day avg"),
      layerContent: hasData,
      includePadding: !hasData
    ) {
      maxHRChart
    }
    .tint(chartData == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.mutedRed))
  }
}

private extension MaxHeartRateStatCard {

  var hasData: Bool {
    chartData?.dataPoints.isNotEmpty ?? false
  }

  @ViewBuilder
  var maxHRChart: some View {
    if let chartData, chartData.dataPoints.isNotEmpty {
      ZStack {
        Chart(chartData.dataPoints) { dataPoint in
          AreaMark(
            x: .value("Day", dataPoint.dayIndex),
            y: .value("Max HR", dataPoint.maxHeartRate)
          )
          .foregroundStyle(
            LinearGradient(
              colors: [Color.mutedRed.opacity(0.5), Color.mutedRed.opacity(0.1)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .interpolationMethod(.catmullRom)

          LineMark(
            x: .value("Day", dataPoint.dayIndex),
            y: .value("Max HR", dataPoint.maxHeartRate)
          )
          .foregroundStyle(.tint)
          .lineStyle(StrokeStyle(lineWidth: 3))
          .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(domain: 0...6)

        statsOverlay
          .zStackAlignment(.bottomTrailing)
      }
    }
  }

  var statsOverlay: some View {
    VStack(alignment: .trailing, spacing: 2) {
      if let chartData {
        Text("\(chartData.averageMaxHR) bpm")
          .font(.title2)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)

        Text("7 day avg")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        MaxHeartRateStatCard(chartData: previewMaxHRData)
        MaxHeartRateStatCard(chartData: nil)
      }
    }
  }
}

private let previewMaxHRData: MaxHeartRateChartData = {
  let dataPoints = [
    MaxHeartRateDataPoint(date: Date(), maxHeartRate: 165, dayIndex: 0),
    MaxHeartRateDataPoint(date: Date(), maxHeartRate: 172, dayIndex: 1),
    MaxHeartRateDataPoint(date: Date(), maxHeartRate: 158, dayIndex: 2),
    MaxHeartRateDataPoint(date: Date(), maxHeartRate: 180, dayIndex: 3),
    MaxHeartRateDataPoint(date: Date(), maxHeartRate: 168, dayIndex: 4),
    MaxHeartRateDataPoint(date: Date(), maxHeartRate: 175, dayIndex: 5),
    MaxHeartRateDataPoint(date: Date(), maxHeartRate: 162, dayIndex: 6)
  ]

  return MaxHeartRateChartData(
    dataPoints: dataPoints,
    averageMaxHR: 169
  )
}()
