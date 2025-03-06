//
//  SleepSegmentSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-03.
//

import SFSafeSymbols
import SwiftUI
import Charts

struct SleepSegmentSummaryCell: View {
  let summary: SleepSegmentSummary

  var body: some View {
    VStack {
      HStack {
        trendImage
          .font(.title)

        Text(summary.name)
          .font(.title3)
          .bold()

        Spacer()

        VStack(alignment: .trailing) {
          HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text("AVG")
              .font(.caption)
              .bold()

            Text("\(summary.averagePercent * 100, specifier: "%.0f")%")
              .font(.largeTitle)
              .foregroundStyle(averageColor)
              .bold()
          }

          Text("Goal \(summary.recommendedPercentMin * 100, specifier: "%.0f")% - \(summary.recommendedPercentMax * 100, specifier: "%.0f")%")
            .font(.caption)
            .bold()
            .foregroundStyle(.secondary)
        }
      }

      chart

      if summary.percentNightsWithValues < 0.8 && summary.segment != .awake {
        HStack(alignment: .top) {
          Image(systemSymbol: .exclamationmarkTriangleFill)
            .foregroundStyle(.orange)
          Text("Only \(summary.percentNightsWithValues, specifier: "%.0f")% of the last month of data contain values. Make sure to wear your watch every night!")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .fontDesign(.rounded)
  }
}

private extension SleepSegmentSummaryCell {

  @ViewBuilder
  var trendImage: some View {
    if summary.averagePercent < summary.recommendedPercentMin {
      Image(systemSymbol: .chevronDownCircle)
        .foregroundStyle(.primary, summary.color)
    } else if summary.averagePercent > summary.recommendedPercentMax {
      Image(systemSymbol: .chevronUpCircle)
        .foregroundStyle(.primary, summary.color)
    } else {
      Image(systemSymbol: .checkmarkCircleFill)
        .foregroundStyle(.white, summary.color)
    }
  }

  var averageColor: Color {
    if
      summary.averagePercent < summary.recommendedPercentMin - 0.05 ||
        summary.averagePercent > summary.recommendedPercentMax + 0.05
    {
      .red
    } else if
      summary.averagePercent < summary.recommendedPercentMin ||
        summary.averagePercent > summary.recommendedPercentMax
    {
      .orange
    } else {
      .primary
    }
  }

  var chart: some View {
    Chart {
      ForEach(summary.dataPoints) { dataPoint in
        BarMark(
          x: .value("Date", dataPoint.date, unit: .day),
          y: .value("Hours", dataPoint.value)
        )
        .foregroundStyle(summary.verticalGradient)
        .cornerRadius(5)
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic) { value in
        AxisGridLine()
        AxisTick()
        AxisValueLabel(format: .dateTime.day())
      }
    }
    .chartYAxis {
      AxisMarks(values: .stride(by: 2)) { value in
        AxisGridLine()
        AxisTick()
        if let hours = value.as(Double.self) {
          AxisValueLabel {
            Text("\(hours, specifier: "%.0f")h")
          }
        }
      }
    }
  }
}

#Preview {
  List {
    Section("Segments") {
      SleepSegmentSummaryCell(
        summary: SleepSegmentSummary(
          segment: .rem,
          averagePercent: 0.27,
          recommendedPercentMin: 0.2,
          recommendedPercentMax: 0.25,
          percentNightsWithValues: 0.95,
          dataPoints: [
            SleepSegmentSummary.DataPoint(date: .now, value: 1.3)
          ]
        )
      )
      SleepSegmentSummaryCell(
        summary: SleepSegmentSummary(
          segment: .core,
          averagePercent: 0.48,
          recommendedPercentMin: 0.45,
          recommendedPercentMax: 0.50,
          percentNightsWithValues: 0.8,
          dataPoints: [
            SleepSegmentSummary.DataPoint(date: .now, value: 2.5)
          ]
        )
      )
      SleepSegmentSummaryCell(
        summary: SleepSegmentSummary(
          segment: .deep,
          averagePercent: 0.13,
          recommendedPercentMin: 0.2,
          recommendedPercentMax: 0.25,
          percentNightsWithValues: 0.3,
          dataPoints: [
            SleepSegmentSummary.DataPoint(date: .now, value: 0.6)
          ]
        )
      )
    }
  }
  .listStyle(.plain)
}
