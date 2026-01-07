//
//  StairClimbSpeedStatCard.swift
//  Bloom
//
//  Created by Assistant on 2026-01-06.
//

import SwiftUI
import Charts

struct StairClimbSpeedStatCard: View {
  let chartData: StairClimbSpeedChartData?

  private static let speedFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 2
    return formatter
  }()

  var body: some View {
    StatCard(
      symbol: .figureStairs,
      title: "Stair Speed",
      value: hasData ? nil : "No Data",
      valueStyle: .largeTinted(nil),
      layerContent: hasData,
      includePadding: !hasData
    ) {
      speedChart
    }
    .tint(chartData == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.mutedOrange))
  }
}

private extension StairClimbSpeedStatCard {

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
              colors: [Color.mutedOrange.opacity(0.5), Color.mutedOrange.opacity(0.1)],
              startPoint: .top,
              endPoint: .bottom
            )
          )

          LineMark(
            x: .value("Date", dataPoint.date),
            y: .value("Speed", dataPoint.value)
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.mutedOrange)
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
      return 0...1
    }

    let values = dataPoints.map(\.value)
    let minValue = values.min() ?? 0
    let maxValue = values.max() ?? 1
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
          .foregroundStyle(.mutedOrange)

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
        StairClimbSpeedStatCard(
          chartData: StairClimbSpeedChartData(
            dataPoints: [
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 6), value: 0.45),
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 5), value: 0.48),
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 4), value: 0.42),
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 3), value: 0.50),
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 2), value: 0.46),
              SpeedDataPoint(date: Date().addingTimeInterval(-86400 * 1), value: 0.49),
              SpeedDataPoint(date: Date(), value: 0.47)
            ],
            averageSpeed: 0.47
          )
        )

        StairClimbSpeedStatCard(chartData: nil)
      }
    }
  }
}
