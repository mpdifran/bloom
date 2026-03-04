//
//  BiologicalAgeWidget.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-01-31.
//

import SwiftUI
import WidgetKit
import BloomFoundation

// MARK: - Timeline Provider

struct BiologicalAgeTimelineProvider: TimelineProvider {
  private static let biologicalAgeKey = "BiologicalAgeProvider.biologicalAge"
  private static let actualAgeKey = "BiologicalAgeProvider.actualAge"

  func placeholder(in context: Context) -> BiologicalAgeEntry {
    BiologicalAgeEntry(date: .now, biologicalAge: 35.0, actualAge: 40.0)
  }

  func getSnapshot(in context: Context, completion: @escaping (BiologicalAgeEntry) -> Void) {
    let entry = loadEntry()
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<BiologicalAgeEntry>) -> Void) {
    let entry = loadEntry()
    // Bio age changes infrequently - refresh every hour
    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
  }

  private func loadEntry() -> BiologicalAgeEntry {
    let bioAge = UserDefaults.group.object(forKey: Self.biologicalAgeKey) as? Double
    let actualAge = UserDefaults.group.object(forKey: Self.actualAgeKey) as? Double
    return BiologicalAgeEntry(date: .now, biologicalAge: bioAge, actualAge: actualAge)
  }
}

// MARK: - Timeline Entry

struct BiologicalAgeEntry: TimelineEntry {
  let date: Date
  let biologicalAge: Double?
  let actualAge: Double?

  var ageDelta: Double? {
    guard let bio = biologicalAge, let actual = actualAge else { return nil }
    return bio - actual
  }

  var isYounger: Bool {
    guard let delta = ageDelta else { return false }
    return delta < 0
  }
}

// MARK: - Widget

struct BiologicalAgeWidget: Widget {
  let kind = "BiologicalAgeWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: BiologicalAgeTimelineProvider()) { entry in
      BiologicalAgeWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Biological Age")
    .description("See your biological age at a glance.")
    .supportedFamilies([.accessoryCircular, .accessoryRectangular])
  }
}

// MARK: - Widget View

struct BiologicalAgeWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: BiologicalAgeEntry

  private var deepLinkURL: URL? {
    URL(string: "bloom://watch/bioage/details")
  }

  var body: some View {
    Group {
      switch family {
      case .accessoryCircular:
        CircularView(entry: entry)
      case .accessoryRectangular:
        RectangularView(entry: entry)
      default:
        CircularView(entry: entry)
      }
    }
    .widgetURL(deepLinkURL)
  }
}

// MARK: - Circular View

private struct CircularView: View {
  let entry: BiologicalAgeEntry

  var body: some View {
    BioAgeMeterView(entry: entry, showCenterText: true)
  }
}

// MARK: - Rectangular View

private struct RectangularView: View {
  let entry: BiologicalAgeEntry

  var body: some View {
    GeometryReader { proxy in
      HStack(spacing: 6) {
        // Bio age meter on the left
        BioAgeMeterView(entry: entry, showCenterText: true)
          .frame(height: proxy.size.height)

        // Text content on the right
        VStack(alignment: .leading, spacing: 2) {
          Text("Bio Age")
            .font(.caption2)

          // Delta indicator
          if let delta = entry.ageDelta {
            HStack(spacing: 2) {
              Image(systemName: entry.isYounger ? "arrow.down" : "arrow.up")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
              Text("\(abs(delta).format(using: .oneDecimalPlace)) yrs")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(entry.isYounger ? Color.mutedGreen : Color.mutedPink)
            .widgetAccentable()
          }
        }

        Spacer(minLength: 0)
      }
    }
  }
}

// MARK: - Previews

#Preview("Circular - Younger (-5)", as: .accessoryCircular) {
  BiologicalAgeWidget()
} timeline: {
  BiologicalAgeEntry(date: .now, biologicalAge: 35.3, actualAge: 40.0)
}

#Preview("Circular - Much Younger (-10)", as: .accessoryCircular) {
  BiologicalAgeWidget()
} timeline: {
  BiologicalAgeEntry(date: .now, biologicalAge: 30.1, actualAge: 40.0)
}

#Preview("Circular - Older (+5)", as: .accessoryCircular) {
  BiologicalAgeWidget()
} timeline: {
  BiologicalAgeEntry(date: .now, biologicalAge: 45.6, actualAge: 40.0)
}

#Preview("Circular - Much Older (+10)", as: .accessoryCircular) {
  BiologicalAgeWidget()
} timeline: {
  BiologicalAgeEntry(date: .now, biologicalAge: 50.8, actualAge: 40.0)
}

#Preview("Circular - Neutral (0)", as: .accessoryCircular) {
  BiologicalAgeWidget()
} timeline: {
  BiologicalAgeEntry(date: .now, biologicalAge: 40.0, actualAge: 40.0)
}

#Preview("Circular - No Data", as: .accessoryCircular) {
  BiologicalAgeWidget()
} timeline: {
  BiologicalAgeEntry(date: .now, biologicalAge: nil, actualAge: nil)
}

#Preview("Rectangular - Younger", as: .accessoryRectangular) {
  BiologicalAgeWidget()
} timeline: {
  BiologicalAgeEntry(date: .now, biologicalAge: 35.2, actualAge: 40.0)
}

#Preview("Rectangular - Older", as: .accessoryRectangular) {
  BiologicalAgeWidget()
} timeline: {
  BiologicalAgeEntry(date: .now, biologicalAge: 44.8, actualAge: 40.0)
}

#Preview("Rectangular - No Data", as: .accessoryRectangular) {
  BiologicalAgeWidget()
} timeline: {
  BiologicalAgeEntry(date: .now, biologicalAge: nil, actualAge: nil)
}
