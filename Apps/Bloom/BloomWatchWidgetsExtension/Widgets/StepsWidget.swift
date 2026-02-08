//
//  StepsWidget.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude Code on 2026-02-07.
//

import BloomFoundation
import Charts
import CoreHealth
import SwiftUI
import WidgetKit
@preconcurrency import HealthKit

// MARK: - Chart Data

private let slotMinutes = 30
private let slotsPerDay = 48 // 24 hours * 2 (30-minute intervals)

struct StepChartPoint: Identifiable {
  var id: Int { slot }
  let slot: Int // 0–47, representing 30-minute periods from midnight
  let cumulativeSteps: Int
}

// MARK: - Timeline Entry

struct StepsEntry: TimelineEntry {
  let date: Date
  let steps: Int?
  let distance: Double?
  let distanceUnitString: String
  let chartDataPoints: [StepChartPoint]

  static var placeholder: StepsEntry {
    StepsEntry(
      date: .now, steps: 4218, distance: 2.3, distanceUnitString: "km",
      chartDataPoints: previewChartData(throughSlot: 30, totalSteps: 4218)
    )
  }

  static var empty: StepsEntry {
    StepsEntry(date: .now, steps: nil, distance: nil, distanceUnitString: "km", chartDataPoints: [])
  }
}

// MARK: - Step Formatting

private func formatStepsCompact(_ steps: Int) -> String {
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

// MARK: - Timeline Provider

struct StepsTimelineProvider: TimelineProvider {
  typealias Entry = StepsEntry

  func placeholder(in context: Context) -> StepsEntry {
    .placeholder
  }

  func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
    if context.isPreview {
      completion(.placeholder)
      return
    }
    Task {
      let entry = await loadEntry()
      completion(entry)
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
    Task {
      let entry = await loadEntry()
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
      let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
      completion(timeline)
    }
  }

  private func loadEntry() async -> StepsEntry {
    let calendar = Calendar.current
    let now = Date()
    let todayRange = DateRange(calendar.startOfDay(for: now), calendar.endOfDay(for: now))

    // Fetch today's total steps
    let stepsQuantity = await HealthStoreFetcher.shared.fetchTotalQuantity(for: .stepCount, dateRange: todayRange)
    let steps: Int? = stepsQuantity.map { Int($0.doubleValue(for: .count()).rounded()) }

    // Determine preferred distance unit
    let distanceUnit: HKUnit
    let distanceUnitString: String
    if let unitString = UserDefaults.group.string(forKey: "HealthUnitPreferences.distanceUnit") {
      let unit = HKUnit(from: unitString)
      distanceUnit = unit
      distanceUnitString = unit.unitString
    } else if Locale.current.measurementSystem == .metric {
      distanceUnit = .meterUnit(with: .kilo)
      distanceUnitString = "km"
    } else {
      distanceUnit = .mile()
      distanceUnitString = "mi"
    }

    // Fetch today's total walking/running distance
    let distanceQuantity = await HealthStoreFetcher.shared.fetchTotalQuantity(
      for: .distanceWalkingRunning,
      dateRange: todayRange
    )
    let distance: Double? = distanceQuantity.map { $0.doubleValue(for: distanceUnit) }

    // Fetch 30-minute interval step data for chart
    let startOfDay = calendar.startOfDay(for: now)
    let intervalSamples = await HealthStoreFetcher.shared.fetchCollatedQuantity(
      for: .stepCount,
      unit: .count(),
      interval: DateComponents(minute: slotMinutes),
      dateRange: todayRange
    )

    var cumulativeTotal = 0
    var chartDataPoints = [StepChartPoint(slot: 0, cumulativeSteps: 0)]
    for sample in intervalSamples {
      let minutesFromMidnight = Int(sample.date.timeIntervalSince(startOfDay) / 60)
      let slot = minutesFromMidnight / slotMinutes
      guard slot >= 0, slot < slotsPerDay else { continue }
      cumulativeTotal += Int(sample.quantity.doubleValue(for: .count()).rounded())
      chartDataPoints.append(StepChartPoint(slot: slot, cumulativeSteps: cumulativeTotal))
    }

    return StepsEntry(
      date: now,
      steps: steps,
      distance: distance,
      distanceUnitString: distanceUnitString,
      chartDataPoints: chartDataPoints
    )
  }
}

// MARK: - Widget

struct StepsWidget: Widget {
  let kind = "StepsWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StepsTimelineProvider()) { entry in
      StepsWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Steps")
    .description("View today's steps and distance.")
    .supportedFamilies([.accessoryCircular, .accessoryRectangular])
  }
}

// MARK: - Widget View

struct StepsWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: StepsEntry

  var body: some View {
    Group {
      switch family {
      case .accessoryCircular:
        CircularStepsView(entry: entry)
      case .accessoryRectangular:
        RectangularStepsView(entry: entry)
      default:
        CircularStepsView(entry: entry)
      }
    }
  }
}

// MARK: - Circular View

private struct CircularStepsView: View {
  let entry: StepsEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      if let steps = entry.steps {
        Text(formatStepsCompact(steps))
          .font(.system(.body, design: .rounded, weight: .bold))
          .foregroundStyle(.mutedYellow)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
      } else {
        Text("--")
          .font(.system(.body, design: .rounded, weight: .bold))
          .foregroundStyle(.gray)
          .lineLimit(1)
      }

      if let distance = entry.distance {
        Text("\(distance.format(using: .oneDecimalPlace)) \(entry.distanceUnitString)")
          .font(.system(.caption2, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
      } else {
        Text("-- \(entry.distanceUnitString)")
          .font(.system(.caption2, design: .rounded))
          .foregroundStyle(.gray)
          .lineLimit(1)
      }
    }
  }
}

// MARK: - Rectangular View

private struct RectangularStepsView: View {
  let entry: StepsEntry

  private static let noonSlot = 24 // 12 hours * 2 (30-minute intervals)

  /// Computes y-axis max so the line stays in the lower portion of the chart,
  /// avoiding overlap with the steps label in the top-left.
  private var yMax: Int {
    let actualMax = entry.chartDataPoints.last?.cumulativeSteps ?? 0
    guard actualMax > 0 else { return 1 }

    let noonCumulative = entry.chartDataPoints.last(where: { $0.slot <= Self.noonSlot })?.cumulativeSteps ?? 0
    let hasPastNoonData = entry.chartDataPoints.contains(where: { $0.slot > Self.noonSlot })

    if hasPastNoonData, noonCumulative > 0 {
      return max(noonCumulative * 2, actualMax)
    } else {
      return actualMax * 2
    }
  }

  var body: some View {
    ZStack {
      if entry.chartDataPoints.count >= 2 {
        Chart {
          ForEach(entry.chartDataPoints) { point in
            LineMark(
              x: .value("Slot", point.slot),
              y: .value("Steps", point.cumulativeSteps)
            )
            .foregroundStyle(Color.mutedYellow)
            .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
            .interpolationMethod(.catmullRom)
          }

          if let lastPoint = entry.chartDataPoints.last {
            PointMark(
              x: .value("Slot", lastPoint.slot),
              y: .value("Steps", lastPoint.cumulativeSteps)
            )
            .foregroundStyle(.background)
            .symbolSize(50)

            PointMark(
              x: .value("Slot", lastPoint.slot),
              y: .value("Steps", lastPoint.cumulativeSteps)
            )
            .foregroundStyle(Color.mutedYellow)
            .symbolSize(20)
          }
        }
        .chartXScale(domain: 0...slotsPerDay - 1)
        .chartYScale(domain: 0...yMax)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
      }

      VStack {
        HStack {
          HStack(spacing: 2) {
            Image(systemName: "figure.walk")
            if let steps = entry.steps {
              Text(NumberFormatter.noDecimalPlaces.string(from: steps as NSNumber) ?? "\(steps)")
            } else {
              Text("--")
            }
          }
          .font(.system(.headline, design: .rounded, weight: .bold))
          .foregroundStyle(.mutedYellow)
          .lineLimit(1)
          .minimumScaleFactor(0.5)

          Spacer()
        }

        Spacer()

        HStack {
          Spacer()

          if let distance = entry.distance {
            Text("\(distance.format(using: .twoDecimalPlaces)) \(entry.distanceUnitString)")
              .font(.system(.subheadline, design: .rounded, weight: .semibold))
              .foregroundStyle(.white)
              .lineLimit(1)
              .minimumScaleFactor(0.5)
          } else {
            Text("-- \(entry.distanceUnitString)")
              .font(.system(.subheadline, design: .rounded, weight: .semibold))
              .foregroundStyle(.gray)
              .lineLimit(1)
          }
        }
      }
    }
  }
}

// MARK: - Preview Data

/// Builds realistic cumulative step data with per-slot increments that mimic daily patterns:
/// sleeping (0-6am), waking/morning commute (7-9am), office (9am-12pm),
/// lunch walk (12-1pm), afternoon (1-5pm), commute/evening (5-7pm), winding down (7-10pm).
private func previewChartData(throughSlot lastSlot: Int, totalSteps: Int) -> [StepChartPoint] {
  // Per-slot weights that shape the daily curve (30-min slots, 0–47)
  let weights: [(slotRange: Range<Int>, weight: Double)] = [
    (0..<14, 0.0),   // 12am–7am: sleeping
    (14..<16, 3.0),  // 7am–8am: waking up, getting ready
    (16..<18, 8.0),  // 8am–9am: morning commute
    (18..<24, 2.0),  // 9am–12pm: office/desk work
    (24..<26, 7.0),  // 12pm–1pm: lunch walk
    (26..<34, 2.5),  // 1pm–5pm: afternoon
    (34..<38, 6.0),  // 5pm–7pm: commute/errands
    (38..<42, 3.0),  // 7pm–9pm: evening activity
    (42..<48, 0.5),  // 9pm–12am: winding down
  ]

  // Build raw weights for each slot up to lastSlot
  var slotWeights = [Double]()
  for slot in 0..<lastSlot {
    let weight = weights.first(where: { $0.slotRange.contains(slot) })?.weight ?? 0
    slotWeights.append(weight)
  }

  let totalWeight = slotWeights.reduce(0, +)
  guard totalWeight > 0 else { return [StepChartPoint(slot: 0, cumulativeSteps: 0)] }

  // Start at midnight with 0, then distribute total steps proportionally
  var cumulative = 0
  var points = [StepChartPoint(slot: 0, cumulativeSteps: 0)]
  for (slot, weight) in slotWeights.enumerated() {
    let increment = Int((weight / totalWeight) * Double(totalSteps))
    cumulative += increment
    if cumulative > 0 {
      points.append(StepChartPoint(slot: slot, cumulativeSteps: cumulative))
    }
  }

  return points
}

// MARK: - Previews

#Preview("Circular - Normal", as: .accessoryCircular) {
  StepsWidget()
} timeline: {
  StepsEntry(date: .now, steps: 4218, distance: 2.3, distanceUnitString: "km", chartDataPoints: [])
}

#Preview("Circular - 10K+", as: .accessoryCircular) {
  StepsWidget()
} timeline: {
  StepsEntry(date: .now, steps: 15340, distance: 8.7, distanceUnitString: "km", chartDataPoints: [])
}

#Preview("Circular - No Data", as: .accessoryCircular) {
  StepsWidget()
} timeline: {
  StepsEntry.empty
}

#Preview("Rectangular - Normal (3pm)", as: .accessoryRectangular) {
  StepsWidget()
} timeline: {
  StepsEntry(
    date: .now, steps: 4218, distance: 2.3, distanceUnitString: "km",
    chartDataPoints: previewChartData(throughSlot: 30, totalSteps: 4218)
  )
}

#Preview("Rectangular - High (6pm)", as: .accessoryRectangular) {
  StepsWidget()
} timeline: {
  StepsEntry(
    date: .now, steps: 15340, distance: 8.7, distanceUnitString: "km",
    chartDataPoints: previewChartData(throughSlot: 36, totalSteps: 15340)
  )
}

#Preview("Rectangular - Early Morning", as: .accessoryRectangular) {
  StepsWidget()
} timeline: {
  StepsEntry(
    date: .now, steps: 312, distance: 0.2, distanceUnitString: "mi",
    chartDataPoints: previewChartData(throughSlot: 17, totalSteps: 312)
  )
}

#Preview("Rectangular - No Data", as: .accessoryRectangular) {
  StepsWidget()
} timeline: {
  StepsEntry.empty
}
