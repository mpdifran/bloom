//
//  StepsWidgetView.swift
//  BloomWidgets
//
//  Created by Claude Code on 2026-02-09.
//

import BloomFoundation
import Charts
import SFSafeSymbols
import SwiftUI
import WidgetKit

struct StepsWidgetView: View {
  let entry: StepsEntry
  @Environment(\.widgetFamily) private var widgetFamily

  var body: some View {
    ZStack {
      if entry.chartDataPoints.count >= 2 {
        chartView
      }

      labelsOverlay
    }
    .widgetURL(URL(string: "https://api.trybloom.app/you/steps"))
    .containerBackground(.background, for: .widget)
  }
}

// MARK: - Chart

private extension StepsWidgetView {

  var chartView: some View {
    Chart {
      ForEach(entry.chartDataPoints) { point in
        LineMark(
          x: .value("Slot", point.slot),
          y: .value("Steps", point.cumulativeSteps)
        )
        .foregroundStyle(Color.mutedYellow)
        .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .interpolationMethod(.catmullRom)
      }

      if let lastPoint = entry.chartDataPoints.last {
        PointMark(
          x: .value("Slot", lastPoint.slot),
          y: .value("Steps", lastPoint.cumulativeSteps)
        )
        .foregroundStyle(.background)
        .symbolSize(outerPointSize)

        PointMark(
          x: .value("Slot", lastPoint.slot),
          y: .value("Steps", lastPoint.cumulativeSteps)
        )
        .foregroundStyle(Color.mutedYellow)
        .symbolSize(innerPointSize)
      }
    }
    .chartXScale(domain: 0...(entry.totalSlots - 1))
    .chartYScale(domain: 0...yMax)
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartLegend(.hidden)
  }
}

// MARK: - Labels

private extension StepsWidgetView {

  var labelsOverlay: some View {
    VStack {
      HStack {
        HStack(spacing: 4) {
          Image(systemSymbol: .figureWalk)
          if let steps = entry.steps {
            Text(formatStepsCompact(steps))
          } else {
            Text(verbatim: "--")
          }
        }
        .font(stepsFont)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(entry.steps != nil ? .mutedYellow : .gray)
        .lineLimit(1)
        .minimumScaleFactor(0.5)

        Spacer()
      }

      Spacer()

      HStack {
        Spacer()

        VStack(alignment: .trailing) {
          Text(entry.timePeriod.displayLabel)
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(.secondary)

          if let distance = entry.distance {
            Text(verbatim: "\(distance.format(using: .twoDecimalPlaces)) \(entry.distanceUnitString)")
          } else {
            Text(verbatim: "-- \(entry.distanceUnitString)")
          }
        }
      }
      .font(distanceFont)
      .bold()
      .fontDesign(.rounded)
      .foregroundStyle(entry.distance != nil ? .primary : .secondary)
      .lineLimit(1)
      .minimumScaleFactor(0.5)
    }
  }
}

// MARK: - Computed Properties

private extension StepsWidgetView {

  var stepsFont: Font {
    widgetFamily == .systemSmall ? .title3 : .title2
  }

  var distanceFont: Font {
    widgetFamily == .systemSmall ? .callout : .body
  }

  var lineWidth: CGFloat {
    widgetFamily == .systemSmall ? 3 : 4
  }

  var outerPointSize: CGFloat {
    widgetFamily == .systemSmall ? 70 : 100
  }

  var innerPointSize: CGFloat {
    widgetFamily == .systemSmall ? 30 : 50
  }

  /// Scale y-axis so the line stays in the lower portion of the chart,
  /// avoiding overlap with the steps label in the top-left.
  var yMax: Int {
    let actualMax = entry.chartDataPoints.last?.cumulativeSteps ?? 0
    guard actualMax > 0 else { return 1 }

    let midSlot = entry.totalSlots / 2
    let midCumulative = entry.chartDataPoints.last(where: { $0.slot <= midSlot })?.cumulativeSteps ?? 0
    let hasPastMidData = entry.chartDataPoints.contains(where: { $0.slot > midSlot })

    if hasPastMidData, midCumulative > 0 {
      return max(midCumulative * 2, actualMax)
    } else {
      return actualMax * 2
    }
  }
}

// MARK: - Formatting

private extension StepsWidgetView {

  func formatStepsCompact(_ steps: Int) -> String {
    if steps < 10_000 {
      return NumberFormatter.noDecimalPlaces.string(from: steps as NSNumber) ?? "\(steps)"
    } else if steps < 1_000_000 {
      let thousands = Double(steps) / 1_000.0
      let formatted = NumberFormatter.oneDecimalPlace.string(from: thousands as NSNumber) ?? String(format: "%.1f", thousands)
      return "\(formatted)K"
    } else {
      let millions = Double(steps) / 1_000_000.0
      let formatted = NumberFormatter.oneDecimalPlace.string(from: millions as NSNumber) ?? String(format: "%.1f", millions)
      return "\(formatted)M"
    }
  }
}
