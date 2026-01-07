//
//  WalkingSpeedStatCard.swift
//  Bloom
//
//  Created by Assistant on 2026-01-06.
//

import SwiftUI
import Charts

struct WalkingSpeedStatCard: View {
  let chartData: WalkingSpeedChartData?

  private static let speedFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.unitOptions = .naturalScale
    formatter.numberFormatter.maximumFractionDigits = 1
    return formatter
  }()

  var body: some View {
    StatCard(
      symbol: .figureWalk,
      title: "Walking Speed",
      value: hasData ? nil : "No Data",
      valueStyle: .largeTinted(nil),
      layerContent: hasData,
      includePadding: !hasData
    ) {
      speedChart
    }
    .tint(chartData == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.mutedYellow))
  }
}

private extension WalkingSpeedStatCard {

  var hasData: Bool {
    chartData?.dataPoints.isNotEmpty ?? false
  }

  @ViewBuilder
  var speedChart: some View {
    if let chartData, chartData.dataPoints.isNotEmpty {
      ZStack {
        Chart(chartData.dataPoints) { dataPoint in
          AreaMark(
            x: .value("Date", dataPoint.date),
            y: .value("Speed", dataPoint.value)
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(
            LinearGradient(
              colors: [Color.mutedYellow.opacity(0.5), Color.mutedYellow.opacity(0.1)],
              startPoint: .top,
              endPoint: .bottom
            )
          )

          LineMark(
            x: .value("Date", dataPoint.date),
            y: .value("Speed", dataPoint.value)
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.mutedYellow)
          .lineStyle(StrokeStyle(lineWidth: 4))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: chartYDomain)
        .padding(.top, 20)

        statsOverlay
          .zStackAlignment(.bottomTrailing)
      }
    }
  }

  var chartYDomain: ClosedRange<Double> {
    guard let dataPoints = chartData?.dataPoints, dataPoints.isNotEmpty else {
      return 0...2
    }

    let values = dataPoints.map(\.value)
    let minValue = values.min() ?? 0
    let maxValue = values.max() ?? 2
    let padding = (maxValue - minValue) * 0.1

    return 0...(maxValue + padding)
  }

  var statsOverlay: some View {
    VStack(alignment: .trailing, spacing: 2) {
      if let chartData {
        Text(formattedSpeed(chartData.averageSpeed))
          .font(.title2)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.mutedYellow)

        Text("7 day avg")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
  }

  func formattedSpeed(_ metersPerSecond: Double) -> String {
    let measurement = Measurement(value: metersPerSecond, unit: UnitSpeed.metersPerSecond)
    return Self.speedFormatter.string(from: measurement)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        WalkingSpeedStatCard(
          chartData: WalkingSpeedChartData(
            dataPoints: [
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 6), value: 1.3),
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 5), value: 1.35),
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 4), value: 1.28),
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 3), value: 1.4),
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 2), value: 1.32),
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 1), value: 1.38),
              SpeedDataPoint(date: Date(), value: 1.36)
            ],
            averageSpeed: 1.34
          )
        )

        WalkingSpeedStatCard(chartData: nil)
      }
    }
  }
}
