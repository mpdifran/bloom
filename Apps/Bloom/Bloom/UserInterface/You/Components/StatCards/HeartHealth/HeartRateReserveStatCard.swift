//
//  HeartRateReserveStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI
import Charts

struct HeartRateReserveStatCard: View {
  let chartData: HeartRateReserveChartData?

  var body: some View {
    StatCard(
      symbol: .arrowUpHeartFill,
      title: "HR Reserve",
      value: hasData ? nil : "No Data",
      valueStyle: .largeTinted(nil),
      layerContent: hasData,
      includePadding: !hasData
    ) {
      hrrChart
    }
    .tint(chartData == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.mutedRed))
  }
}

private extension HeartRateReserveStatCard {

  var hasData: Bool {
    chartData?.dataPoints.isNotEmpty ?? false
  }

  @ViewBuilder
  var hrrChart: some View {
    if let chartData, chartData.dataPoints.isNotEmpty {
      ZStack {
        Chart(chartData.dataPoints) { dataPoint in
          // Area between resting HR (bottom) and max HR (top)
          AreaMark(
            x: .value("Day", dataPoint.dayIndex),
            yStart: .value("Resting", dataPoint.restingHeartRate),
            yEnd: .value("Max", dataPoint.maxHeartRate)
          )
          .foregroundStyle(
            LinearGradient(
              colors: [Color.mutedRed.opacity(0.7), Color.mutedRed.opacity(0.3)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .interpolationMethod(.catmullRom)

          // Top line (max HR)
          LineMark(
            x: .value("Day", dataPoint.dayIndex),
            y: .value("HR", dataPoint.maxHeartRate),
            series: .value("Series", "Max")
          )
          .foregroundStyle(.tint)
          .lineStyle(StrokeStyle(lineWidth: 2))
          .interpolationMethod(.catmullRom)

          // Bottom line (resting HR)
          LineMark(
            x: .value("Day", dataPoint.dayIndex),
            y: .value("HR", dataPoint.restingHeartRate),
            series: .value("Series", "Resting")
          )
          .foregroundStyle(.tint.opacity(0.5))
          .lineStyle(StrokeStyle(lineWidth: 2))
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
        Text("\(chartData.currentHRR) bpm")
          .font(.title2)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)

        Text("7 day avg reserve")
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
        HeartRateReserveStatCard(chartData: previewHRRData)
        HeartRateReserveStatCard(chartData: nil)
      }
    }
  }
}

private let previewHRRData: HeartRateReserveChartData = {
  let dataPoints = [
    HeartRateReserveDataPoint(date: Date(), maxHeartRate: 165, restingHeartRate: 58, dayIndex: 0),
    HeartRateReserveDataPoint(date: Date(), maxHeartRate: 172, restingHeartRate: 56, dayIndex: 1),
    HeartRateReserveDataPoint(date: Date(), maxHeartRate: 168, restingHeartRate: 57, dayIndex: 2),
    HeartRateReserveDataPoint(date: Date(), maxHeartRate: 180, restingHeartRate: 55, dayIndex: 3),
    HeartRateReserveDataPoint(date: Date(), maxHeartRate: 175, restingHeartRate: 54, dayIndex: 4),
    HeartRateReserveDataPoint(date: Date(), maxHeartRate: 178, restingHeartRate: 56, dayIndex: 5),
    HeartRateReserveDataPoint(date: Date(), maxHeartRate: 170, restingHeartRate: 55, dayIndex: 6)
  ]

  return HeartRateReserveChartData(
    dataPoints: dataPoints,
    currentHRR: 115  // 170 - 55
  )
}()
