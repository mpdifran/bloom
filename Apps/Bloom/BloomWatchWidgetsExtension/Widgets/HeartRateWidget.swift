//
//  HeartRateWidget.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude Code on 2026-02-07.
//

import BloomFoundation
import CoreHealth
import SwiftUI
import WidgetKit
@preconcurrency import HealthKit

// MARK: - Timeline Entry

struct HeartRateEntry: TimelineEntry {
  let date: Date
  let latestHeartRate: Int?
  let minHeartRate: Int?
  let maxHeartRate: Int?

  var progress: Double {
    guard let latest = latestHeartRate,
          let minHR = minHeartRate,
          let maxHR = maxHeartRate,
          maxHR > minHR else {
      return 0
    }
    return max(0, min(1, Double(latest - minHR) / Double(maxHR - minHR)))
  }

  static var placeholder: HeartRateEntry {
    HeartRateEntry(date: .now, latestHeartRate: 72, minHeartRate: 58, maxHeartRate: 142)
  }

  static var empty: HeartRateEntry {
    HeartRateEntry(date: .now, latestHeartRate: nil, minHeartRate: nil, maxHeartRate: nil)
  }
}

// MARK: - Timeline Provider

struct HeartRateTimelineProvider: TimelineProvider {
  typealias Entry = HeartRateEntry

  func placeholder(in context: Context) -> HeartRateEntry {
    .placeholder
  }

  func getSnapshot(in context: Context, completion: @escaping (HeartRateEntry) -> Void) {
    if context.isPreview {
      completion(.placeholder)
      return
    }
    Task {
      let entry = await loadEntry()
      completion(entry)
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HeartRateEntry>) -> Void) {
    Task {
      let entry = await loadEntry()
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
      let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
      completion(timeline)
    }
  }

  private func loadEntry() async -> HeartRateEntry {
    let calendar = Calendar.current
    let now = Date()
    let todayRange = DateRange(calendar.startOfDay(for: now), calendar.endOfDay(for: now))

    // Fetch latest heart rate sample
    let latestSample = await HealthStoreFetcher.shared.fetchLatestSample(for: .heartRate)
    let latestBPM: Int? = latestSample.map { Int($0.quantity.doubleValue(for: .bpm()).rounded()) }

    // Fetch today's min/max
    let stats = await HealthStoreFetcher.shared.fetchDiscreteStatistics(
      for: .heartRate,
      unit: .bpm(),
      dateRange: todayRange
    )
    let minBPM: Int? = stats.min.map { Int($0.rounded()) }
    let maxBPM: Int? = stats.max.map { Int($0.rounded()) }

    return HeartRateEntry(
      date: now,
      latestHeartRate: latestBPM,
      minHeartRate: minBPM,
      maxHeartRate: maxBPM
    )
  }
}

// MARK: - Widget

struct HeartRateWidget: Widget {
  let kind = "HeartRateWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: HeartRateTimelineProvider()) { entry in
      HeartRateWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Heart Rate")
    .description("View your latest heart rate with today's range.")
    .supportedFamilies([.accessoryCircular, .accessoryCorner])
  }
}

// MARK: - Widget View

struct HeartRateWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: HeartRateEntry

  var body: some View {
    Group {
      switch family {
      case .accessoryCircular:
        CircularHeartRateView(entry: entry)
      case .accessoryCorner:
        CornerHeartRateView(entry: entry)
      default:
        CircularHeartRateView(entry: entry)
      }
    }
  }
}

// MARK: - Circular View

private struct CircularHeartRateView: View {
  let entry: HeartRateEntry

  private let gradient = Gradient(colors: [.mutedRed, .softRed, .softPink])

  var body: some View {
    if let latest = entry.latestHeartRate,
       let minHR = entry.minHeartRate,
       let maxHR = entry.maxHeartRate,
       maxHR > minHR {
      Gauge(value: Double(latest), in: Double(minHR)...Double(maxHR)) {
        Image(systemName: "heart.fill")
      } currentValueLabel: {
        HStack(spacing: 0) {
          Image(systemName: "heart.fill")
            .font(.system(size: 10))
          Text(verbatim: "\(latest)")
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
      } minimumValueLabel: {
        Text(verbatim: "\(minHR)")
      } maximumValueLabel: {
        Text(verbatim: "\(maxHR)")
      }
      .gaugeStyle(.accessoryCircular)
      .tint(gradient)
      .widgetAccentable()
    } else {
      Gauge(value: 0) {
        Image(systemName: "heart.fill")
      } currentValueLabel: {
        Text(verbatim: "--")
      }
      .gaugeStyle(.accessoryCircular)
      .tint(gradient)
      .widgetAccentable()
    }
  }
}

// MARK: - Corner View

private struct CornerHeartRateView: View {
  let entry: HeartRateEntry

  private let gradient = Gradient(colors: [.mutedRed, .softRed, .softPink])

  var body: some View {
    if let latest = entry.latestHeartRate,
       let minHR = entry.minHeartRate,
       let maxHR = entry.maxHeartRate,
       maxHR > minHR {
      HStack(spacing: 0) {
        Image(systemName: "heart.fill")
          .foregroundStyle(.mutedRed)
          .font(.system(size: 10))
        Text(verbatim: "\(latest)")
          .foregroundStyle(.white)
          .font(.system(size: 40))
          .bold()
          .fontDesign(.rounded)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
      }
      .widgetAccentable()
      .widgetLabel {
        Gauge(value: Double(latest), in: Double(minHR)...Double(maxHR)) {
          Image(systemName: "heart.fill")
        } currentValueLabel: {
          Text(verbatim: "\(latest)")
        } minimumValueLabel: {
          Text(verbatim: "\(minHR)")
        } maximumValueLabel: {
          Text(verbatim: "\(maxHR)")
        }
        .tint(gradient)
      }
    } else {
      HStack(spacing: 0) {
        Image(systemName: "heart.fill")
          .foregroundStyle(.gray)
          .font(.system(size: 10))
        Text(verbatim: "--")
          .foregroundStyle(.gray)
          .font(.system(size: 40))
          .bold()
          .fontDesign(.rounded)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
      }
      .widgetLabel {
        Gauge(value: Double(0), in: Double(0)...Double(1)) {
          Image(systemName: "heart.fill")
        } currentValueLabel: {
          Text("")
        } minimumValueLabel: {
          Text("")
        } maximumValueLabel: {
          Text("")
        }
        .tint(.gray)
      }
    }
  }
}

// MARK: - Previews

#Preview("Circular - Normal", as: .accessoryCircular) {
  HeartRateWidget()
} timeline: {
  HeartRateEntry(date: .now, latestHeartRate: 72, minHeartRate: 58, maxHeartRate: 142)
}

#Preview("Circular - High", as: .accessoryCircular) {
  HeartRateWidget()
} timeline: {
  HeartRateEntry(date: .now, latestHeartRate: 165, minHeartRate: 55, maxHeartRate: 170)
}

#Preview("Circular - Low", as: .accessoryCircular) {
  HeartRateWidget()
} timeline: {
  HeartRateEntry(date: .now, latestHeartRate: 52, minHeartRate: 48, maxHeartRate: 130)
}

#Preview("Circular - No Data", as: .accessoryCircular) {
  HeartRateWidget()
} timeline: {
  HeartRateEntry.empty
}

#Preview("Corner - Normal", as: .accessoryCorner) {
  HeartRateWidget()
} timeline: {
  HeartRateEntry(date: .now, latestHeartRate: 72, minHeartRate: 58, maxHeartRate: 142)
}

#Preview("Corner - No Data", as: .accessoryCorner) {
  HeartRateWidget()
} timeline: {
  HeartRateEntry.empty
}
