//
//  BioAgeHistoryChartCell.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-01.
//

import SwiftUI
import Charts
import BloomFoundation

struct BioAgeHistoryChartCell: View {
  let chartData: [WatchBioAgeChartPoint]?
  let actualAge: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Bio Age History")
        .font(.caption2)
        .foregroundStyle(.secondary)

      if let data = chartData, data.count >= 2 {
        chartView(data: data)
      } else {
        noDataView
      }
    }
    .padding(.vertical, 8)
  }
}

private extension BioAgeHistoryChartCell {

  func chartView(data: [WatchBioAgeChartPoint]) -> some View {
    VStack(spacing: 4) {
      Chart {
        ForEach(data) { point in
          // Actual age line (horizontal reference)
          LineMark(
            x: .value("Date", point.date, unit: .day),
            y: .value("Age", actualAge),
            series: .value("Type", "Actual")
          )
          .foregroundStyle(.fill)
          .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))

          // Bio age line
          LineMark(
            x: .value("Date", point.date, unit: .day),
            y: .value("Age", point.biologicalAge),
            series: .value("Type", "Bio")
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.mutedGreen)
          .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
        }

        // End point marker
        if let lastPoint = data.last {
          PointMark(
            x: .value("Date", lastPoint.date, unit: .day),
            y: .value("Age", lastPoint.biologicalAge)
          )
          .foregroundStyle(.background)
          .symbolSize(40)

          PointMark(
            x: .value("Date", lastPoint.date, unit: .day),
            y: .value("Age", lastPoint.biologicalAge)
          )
          .foregroundStyle(.mutedGreen)
          .symbolSize(30)
        }
      }
      .chartYScale(domain: chartYRange(for: data))
      .chartXAxis(.hidden)
      .chartYAxis(.hidden)
      .frame(height: 50)

      // Legend
      HStack(spacing: 8) {
        HStack(spacing: 4) {
          Circle()
            .fill(.fill)
            .frame(width: 6, height: 6)
          Text("Actual: \(Int(actualAge))")
            .font(.system(size: 9))
            .foregroundStyle(.secondary)
        }
        HStack(spacing: 4) {
          Circle()
            .fill(.mutedGreen)
            .frame(width: 6, height: 6)
          Text("Bio Age")
            .font(.system(size: 9))
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  var noDataView: some View {
    Text("Not enough data")
      .font(.caption2)
      .foregroundStyle(.secondary)
      .frame(height: 60)
      .frame(maxWidth: .infinity)
  }

  func chartYRange(for data: [WatchBioAgeChartPoint]) -> ClosedRange<Double> {
    let bioAges = data.map(\.biologicalAge)
    let minBio = bioAges.min() ?? actualAge
    let maxBio = bioAges.max() ?? actualAge

    let minValue = min(minBio, actualAge) - 2
    let maxValue = max(maxBio, actualAge) + 2

    return minValue...maxValue
  }
}

#Preview {
  PreviewEnvironment {
    List {
      BioAgeHistoryChartCell(
        chartData: [
          WatchBioAgeChartPoint(date: Date().addingTimeInterval(-86400 * 13), biologicalAge: 35.5),
          WatchBioAgeChartPoint(date: Date().addingTimeInterval(-86400 * 10), biologicalAge: 35.2),
          WatchBioAgeChartPoint(date: Date().addingTimeInterval(-86400 * 7), biologicalAge: 34.8),
          WatchBioAgeChartPoint(date: Date().addingTimeInterval(-86400 * 4), biologicalAge: 34.5),
          WatchBioAgeChartPoint(date: Date(), biologicalAge: 34.2)
        ],
        actualAge: 36
      )

      BioAgeHistoryChartCell(
        chartData: nil,
        actualAge: 36
      )
    }
    .listStyle(.carousel)
  }
}
