//
//  TrainingLoadChartView.swift
//  Bloom
//
//  Created by Assistant on 2025-09-12.
//

import SwiftUI
import Charts
import CoreHealth
import BloomFoundation
import SFSafeSymbols

struct TrainingLoadChartView: View {
  let summary: TrainingLoadSummary?

  @State private var presentedSheet: AnyView?

  var body: some View {
    Group {
      if let summary {
        VStack {
          chart(summary: summary)
          statusHeader(summary: summary)
        }
      } else {
        ProgressView()
          .horizontallyCentered()
      }
    }
    .frame(height: 250)
    .sheet($presentedSheet)
  }
}

private extension TrainingLoadChartView {

  struct ZoneBoundaries: Identifiable {
    var id: Date { date }
    let date: Date
    let steadyUpper: Double
    let steadyLower: Double
    let aboveBelowUpper: Double
    let aboveBelowLower: Double
  }

  func zoneBoundaries(for summary: TrainingLoadSummary) -> [ZoneBoundaries] {
    var boundaries = summary.twentyEightDayTrend.map { point in
      ZoneBoundaries(
        date: point.date,
        steadyUpper: point.value * 1.25,
        steadyLower: point.value * 0.75,
        aboveBelowUpper: point.value * 1.60,
        aboveBelowLower: point.value * 0.40
      )
    }

    // Project ~3 days forward using rest-day decay
    if let lastPoint = summary.twentyEightDayTrend.last {
      let alpha = 2.0 / 29.0
      let decayFactor = 1 - alpha
      var value = lastPoint.value

      for dayOffset in 1...3 {
        value *= decayFactor
        if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: lastPoint.date) {
          boundaries.append(ZoneBoundaries(
            date: date,
            steadyUpper: value * 1.25,
            steadyLower: value * 0.75,
            aboveBelowUpper: value * 1.60,
            aboveBelowLower: value * 0.40
          ))
        }
      }
    }

    return boundaries
  }

  func statusHeader(summary: TrainingLoadSummary) -> some View {
    HStack {
      Spacer()

      Button {
        presentedSheet = TrainingLoadLegendView().asAny
      } label: {
        VStack(alignment: .trailing) {
          HStack(spacing: 4) {
            Text(summary.status.rawValue)
            Image(systemSymbol: .infoCircle)
              .font(.body)
          }
          .foregroundStyle(.blue)

          Text(String(format: "%+.0f%%", summary.percentageDifference))
            .foregroundStyle(.text.secondary)
        }
      }
      .buttonStyle(.plain)
    }
    .font(.title3)
    .bold()
    .fontDesign(.rounded)
    .padding(.horizontal)
  }

  func chart(summary: TrainingLoadSummary) -> some View {
    let boundaries = zoneBoundaries(for: summary)
    let maxY = maxYValue(for: summary)

    return Chart {
      // Layer 2a: Above zone
      ForEach(boundaries) { boundary in
        AreaMark(
          x: .value("Date", boundary.date),
          yStart: .value("Value", boundary.steadyUpper),
          yEnd: .value("Value", boundary.aboveBelowUpper),
          series: .value("Series", "Above")
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(.blue.opacity(0.6))
      }

      // Layer 2b: Below zone
      ForEach(boundaries) { boundary in
        AreaMark(
          x: .value("Date", boundary.date),
          yStart: .value("Value", boundary.aboveBelowLower),
          yEnd: .value("Value", boundary.steadyLower),
          series: .value("Series", "Below")
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(.blue.opacity(0.6))
      }

      // Layer 3: Steady zone (innermost)
      ForEach(boundaries) { boundary in
        AreaMark(
          x: .value("Date", boundary.date),
          yStart: .value("Value", boundary.steadyLower),
          yEnd: .value("Value", boundary.steadyUpper),
          series: .value("Series", "Steady")
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(.blue)
      }

      // Layer 4: 7-day trend line
      ForEach(summary.sevenDayTrend, id: \.date) { point in
        LineMark(
          x: .value("Date", point.date),
          y: .value("Value", point.value),
          series: .value("Series", "7-day")
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(.text)
        .lineStyle(StrokeStyle(lineWidth: 3))
      }

      // Layer 5: Current value point
      if let currentPoint = summary.sevenDayTrend.last {
        PointMark(
          x: .value("Date", currentPoint.date),
          y: .value("Value", currentPoint.value)
        )
        .symbol {
          Circle()
            .strokeBorder(.text, lineWidth: 2)
            .background {
              Circle()
                .fill(.invertedText)
            }
            .frame(width: 8, height: 8)
        }
      }
    }
    .chartYScale(domain: 0...maxY)
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartLegend(.hidden)
  }

  func maxYValue(for summary: TrainingLoadSummary) -> Double {
    let sevenDayMax = summary.sevenDayTrend.map(\.value).max() ?? 0
    let zoneMax = summary.twentyEightDayTrend.map { $0.value * 1.5 }.max() ?? 0
    return max(sevenDayMax, zoneMax) * 1.1
  }
}

// MARK: - Mock Data

extension TrainingLoadSummary {
  static var mockSteady: TrainingLoadSummary {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    let sevenDayTrend = (0..<28).map { dayOffset in
      let date = calendar.date(byAdding: .day, value: -27 + dayOffset, to: today)!
      let base = 50.0 + sin(Double(dayOffset) * 0.3) * 5
      return DateValueSample(date: date, value: base)
    }

    let twentyEightDayTrend = (0..<28).map { dayOffset in
      let date = calendar.date(byAdding: .day, value: -27 + dayOffset, to: today)!
      return DateValueSample(date: date, value: 48.0 + Double(dayOffset) * 0.1)
    }

    return TrainingLoadSummary(
      dateRange: DateRange(
        calendar.date(byAdding: .day, value: -27, to: today)!,
        today
      ),
      currentSevenDayAverage: 50,
      currentTwentyEightDayAverage: 49,
      percentageDifference: 2.0,
      status: .steady,
      sevenDayTrend: sevenDayTrend,
      twentyEightDayTrend: twentyEightDayTrend,
      dailyLoads: sevenDayTrend
    )
  }

  static var mockAbove: TrainingLoadSummary {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    let sevenDayTrend = (0..<28).map { dayOffset in
      let date = calendar.date(byAdding: .day, value: -27 + dayOffset, to: today)!
      let base = 45.0 + Double(dayOffset) * 1.2 + sin(Double(dayOffset) * 0.4) * 4
      return DateValueSample(date: date, value: base)
    }

    let twentyEightDayTrend = (0..<28).map { dayOffset in
      let date = calendar.date(byAdding: .day, value: -27 + dayOffset, to: today)!
      return DateValueSample(date: date, value: 50.0 + Double(dayOffset) * 0.3)
    }

    return TrainingLoadSummary(
      dateRange: DateRange(
        calendar.date(byAdding: .day, value: -27, to: today)!,
        today
      ),
      currentSevenDayAverage: 72,
      currentTwentyEightDayAverage: 55,
      percentageDifference: 30.9,
      status: .above,
      sevenDayTrend: sevenDayTrend,
      twentyEightDayTrend: twentyEightDayTrend,
      dailyLoads: sevenDayTrend
    )
  }

  static var mockWellAbove: TrainingLoadSummary {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    let sevenDayTrend = (0..<28).map { dayOffset in
      let date = calendar.date(byAdding: .day, value: -27 + dayOffset, to: today)!
      let base = 40.0 + Double(dayOffset) * 2.5 + sin(Double(dayOffset) * 0.5) * 6
      return DateValueSample(date: date, value: base)
    }

    let twentyEightDayTrend = (0..<28).map { dayOffset in
      let date = calendar.date(byAdding: .day, value: -27 + dayOffset, to: today)!
      return DateValueSample(date: date, value: 45.0 + Double(dayOffset) * 0.4)
    }

    return TrainingLoadSummary(
      dateRange: DateRange(
        calendar.date(byAdding: .day, value: -27, to: today)!,
        today
      ),
      currentSevenDayAverage: 100,
      currentTwentyEightDayAverage: 55,
      percentageDifference: 81.8,
      status: .wellAbove,
      sevenDayTrend: sevenDayTrend,
      twentyEightDayTrend: twentyEightDayTrend,
      dailyLoads: sevenDayTrend
    )
  }
}

#Preview("Steady") {
  PreviewEnvironment {
    BloomScrollView(padding: .vertical) {
      TrainingLoadChartView(summary: .mockSteady)
    }
  }
}

#Preview("Above") {
  PreviewEnvironment {
    BloomScrollView(padding: .vertical) {
      TrainingLoadChartView(summary: .mockAbove)
    }
  }
}

#Preview("Well Above") {
  PreviewEnvironment {
    BloomScrollView(padding: .vertical) {
      TrainingLoadChartView(summary: .mockWellAbove)
    }
  }
}
