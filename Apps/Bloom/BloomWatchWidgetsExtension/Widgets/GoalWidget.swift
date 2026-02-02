//
//  GoalWidget.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-02-01.
//

import AppIntents
import BloomFoundation
import SwiftUI
import WidgetKit

// MARK: - Widget

struct WatchGoalWidget: Widget {
  let kind = "WatchGoalWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: WatchGoalWidgetIntent.self,
      provider: WatchGoalTimelineProvider()
    ) { entry in
      WatchGoalWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Goal")
    .description("Track your goal progress at a glance.")
    .supportedFamilies([
      .accessoryCircular,
      .accessoryRectangular,
      .accessoryCorner,
      .accessoryInline
    ])
  }
}

// MARK: - Timeline Entry

struct WatchGoalEntry: TimelineEntry {
  let date: Date
  let goalId: String
  let metricName: String
  let metricSystemImage: String
  let metricColorHex: String?
  let currentValue: Double
  let targetValue: Double
  let unitString: String
  let timePeriod: String
  let isEmpty: Bool

  var progress: Double {
    guard targetValue > 0 else { return 0 }
    return min(currentValue / targetValue, 1.0)
  }

  var progressPercent: Int {
    Int(progress * 100)
  }

  var metricColor: Color {
    if let hex = metricColorHex, let color = Color(hex: hex) {
      return color
    }
    return .accentColor
  }

  static var placeholder: WatchGoalEntry {
    WatchGoalEntry(
      date: .now,
      goalId: "placeholder",
      metricName: "Steps",
      metricSystemImage: "figure.walk",
      metricColorHex: nil,
      currentValue: 7500,
      targetValue: 10000,
      unitString: "steps",
      timePeriod: "daily",
      isEmpty: false
    )
  }

  static var empty: WatchGoalEntry {
    WatchGoalEntry(
      date: .now,
      goalId: "",
      metricName: "No Goal",
      metricSystemImage: "target",
      metricColorHex: nil,
      currentValue: 0,
      targetValue: 0,
      unitString: "",
      timePeriod: "daily",
      isEmpty: true
    )
  }
}

// MARK: - Timeline Provider

struct WatchGoalTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = WatchGoalEntry
  typealias Intent = WatchGoalWidgetIntent

  private static let goalsKey = "WatchGoalProvider.goals"

  func placeholder(in context: Context) -> WatchGoalEntry {
    .placeholder
  }

  func snapshot(for configuration: WatchGoalWidgetIntent, in context: Context) async -> WatchGoalEntry {
    if context.isPreview {
      return .placeholder
    }
    return makeEntry(for: configuration)
  }

  func timeline(for configuration: WatchGoalWidgetIntent, in context: Context) async -> Timeline<WatchGoalEntry> {
    let entry = makeEntry(for: configuration)

    // If empty, just refresh every 15 minutes
    guard !entry.isEmpty else {
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
      return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    // Calculate next reset time based on time period
    let calendar = Calendar.current
    let now = Date.now
    var entries: [WatchGoalEntry] = [entry]

    if let resetDate = nextResetDate(for: entry.timePeriod, from: now, using: calendar) {
      // Add a reset entry at the deadline with currentValue = 0
      let resetEntry = WatchGoalEntry(
        date: resetDate,
        goalId: entry.goalId,
        metricName: entry.metricName,
        metricSystemImage: entry.metricSystemImage,
        metricColorHex: entry.metricColorHex,
        currentValue: 0,
        targetValue: entry.targetValue,
        unitString: entry.unitString,
        timePeriod: entry.timePeriod,
        isEmpty: false
      )
      entries.append(resetEntry)
    }

    // Refresh at the end of the timeline to get updated data
    return Timeline(entries: entries, policy: .atEnd)
  }

  /// Calculates the next reset date for a goal based on its time period
  private func nextResetDate(for timePeriod: String, from date: Date, using calendar: Calendar) -> Date? {
    switch timePeriod {
    case "daily":
      return calendar.startOfTomorrow(for: date)
    case "weekly":
      return calendar.dateInterval(of: .weekOfYear, for: date)?.end
    case "monthly":
      return calendar.dateInterval(of: .month, for: date)?.end
    case "yearly":
      return calendar.dateInterval(of: .year, for: date)?.end
    default:
      return calendar.startOfTomorrow(for: date)
    }
  }

  /// Required for watchOS - provides pre-configured widget options since
  /// watchOS doesn't have an interactive configuration UI
  func recommendations() -> [AppIntentRecommendation<WatchGoalWidgetIntent>] {
    let goals = loadCachedGoals()

    return goals.map { goal in
      let intent = WatchGoalWidgetIntent()
      intent.goal = WatchGoalEntity(
        id: goal.id,
        name: goal.metricName,
        systemImage: goal.metricSystemImage
      )

      return AppIntentRecommendation(intent: intent, description: goal.metricName)
    }
  }

  private func makeEntry(for configuration: WatchGoalWidgetIntent) -> WatchGoalEntry {
    let goals = loadCachedGoals()

    // Get selected goal ID or fall back to first available
    let goalId: String
    if let configuredGoalId = configuration.goal?.id {
      goalId = configuredGoalId
    } else if let firstGoal = goals.first {
      goalId = firstGoal.id
    } else {
      return .empty
    }

    // Find goal data
    guard let goal = goals.first(where: { $0.id == goalId }) else {
      return .empty
    }

    return WatchGoalEntry(
      date: .now,
      goalId: goal.id,
      metricName: goal.metricName,
      metricSystemImage: goal.metricSystemImage,
      metricColorHex: goal.metricColorHex,
      currentValue: goal.currentValue,
      targetValue: goal.targetValue,
      unitString: goal.targetUnit,
      timePeriod: goal.timePeriod,
      isEmpty: false
    )
  }

  private func loadCachedGoals() -> [WatchGoal] {
    guard let data = UserDefaults.group.data(forKey: Self.goalsKey),
          let goals = try? JSONDecoder().decode([WatchGoal].self, from: data) else {
      return []
    }
    return goals
  }
}

// MARK: - Widget View

struct WatchGoalWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: WatchGoalEntry

  var body: some View {
    Group {
      switch family {
      case .accessoryCircular:
        CircularGoalView(entry: entry)
      case .accessoryRectangular:
        RectangularGoalView(entry: entry)
      case .accessoryCorner:
        CornerGoalView(entry: entry)
      case .accessoryInline:
        InlineGoalView(entry: entry)
      default:
        CircularGoalView(entry: entry)
      }
    }
    .widgetURL(URL(string: "bloom://watch/goals/\(entry.goalId)"))
  }
}

// MARK: - Circular View

private struct CircularGoalView: View {
  let entry: WatchGoalEntry

  var body: some View {
    if entry.isEmpty {
      Image(systemName: "target")
        .font(.title2)
        .foregroundStyle(.secondary)
    } else {
      GoalProgressRing(
        progress: entry.progress,
        systemImage: entry.metricSystemImage,
        tintColor: entry.metricColor
      )
    }
  }
}

// MARK: - Rectangular View

private struct RectangularGoalView: View {
  let entry: WatchGoalEntry

  var body: some View {
    if entry.isEmpty {
      HStack {
        Image(systemName: "target")
          .font(.title2)
          .foregroundStyle(.secondary)
        Text("Set a goal in Bloom")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    } else {
      GeometryReader { proxy in
        HStack(spacing: 6) {
          GoalProgressRing(
            progress: entry.progress,
            systemImage: entry.metricSystemImage,
            tintColor: entry.metricColor
          )
          .frame(height: proxy.size.height)

          VStack(alignment: .leading, spacing: 2) {
            Text(entry.metricName)
              .font(.caption2)
              .fontWeight(.semibold)
              .lineLimit(1)

            HStack(spacing: 2) {
              Text(entry.currentValue.format(using: .noDecimalPlaces))
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(entry.metricColor)
              Text("/")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Text("\(entry.targetValue.format(using: .noDecimalPlaces)) \(entry.unitString)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .lineLimit(1)
          }

          Spacer(minLength: 0)
        }
      }
    }
  }
}

// MARK: - Corner View

private struct CornerGoalView: View {
  let entry: WatchGoalEntry

  var body: some View {
    if entry.isEmpty {
      Text("--")
        .font(.system(.title3, design: .rounded, weight: .bold))
        .foregroundStyle(.secondary)
        .widgetLabel {
          Text("No Goal")
        }
    } else {
      Gauge(value: entry.progress) {
        Image(systemName: entry.metricSystemImage)
      } currentValueLabel: {
        Text(entry.currentValue.format(using: .noDecimalPlaces))
          .font(.system(.title3, design: .rounded, weight: .bold))
      }
      .gaugeStyle(.accessoryCircularCapacity)
      .tint(entry.metricColor)
      .widgetLabel {
        Text(entry.metricName)
      }
    }
  }
}

// MARK: - Inline View

private struct InlineGoalView: View {
  let entry: WatchGoalEntry

  var body: some View {
    if entry.isEmpty {
      Label("No Goal", systemImage: "target")
    } else {
      Label {
        Text("\(entry.currentValue.format(using: .noDecimalPlaces)) / \(entry.targetValue.format(using: .noDecimalPlaces)) \(entry.unitString)")
      } icon: {
        Image(systemName: entry.metricSystemImage)
      }
    }
  }
}

// MARK: - Previews

#Preview("Circular - Steps", as: .accessoryCircular) {
  WatchGoalWidget()
} timeline: {
  WatchGoalEntry(
    date: .now,
    goalId: "steps",
    metricName: "Steps",
    metricSystemImage: "figure.walk",
    metricColorHex: "#4CAF50",
    currentValue: 7500,
    targetValue: 10000,
    unitString: "steps",
    timePeriod: "daily",
    isEmpty: false
  )
}

#Preview("Circular - Water", as: .accessoryCircular) {
  WatchGoalWidget()
} timeline: {
  WatchGoalEntry(
    date: .now,
    goalId: "water",
    metricName: "Water",
    metricSystemImage: "drop.fill",
    metricColorHex: "#2196F3",
    currentValue: 6,
    targetValue: 8,
    unitString: "cups",
    timePeriod: "daily",
    isEmpty: false
  )
}

#Preview("Circular - Empty", as: .accessoryCircular) {
  WatchGoalWidget()
} timeline: {
  WatchGoalEntry.empty
}

#Preview("Rectangular - Steps", as: .accessoryRectangular) {
  WatchGoalWidget()
} timeline: {
  WatchGoalEntry(
    date: .now,
    goalId: "steps",
    metricName: "Steps",
    metricSystemImage: "figure.walk",
    metricColorHex: "#4CAF50",
    currentValue: 7543,
    targetValue: 10000,
    unitString: "steps",
    timePeriod: "daily",
    isEmpty: false
  )
}

#Preview("Rectangular - Calories", as: .accessoryRectangular) {
  WatchGoalWidget()
} timeline: {
  WatchGoalEntry(
    date: .now,
    goalId: "calories",
    metricName: "Calories",
    metricSystemImage: "flame.fill",
    metricColorHex: "#FF9800",
    currentValue: 1850,
    targetValue: 2200,
    unitString: "kcal",
    timePeriod: "daily",
    isEmpty: false
  )
}

#Preview("Rectangular - Empty", as: .accessoryRectangular) {
  WatchGoalWidget()
} timeline: {
  WatchGoalEntry.empty
}

#Preview("Corner - Steps", as: .accessoryCorner) {
  WatchGoalWidget()
} timeline: {
  WatchGoalEntry(
    date: .now,
    goalId: "steps",
    metricName: "Steps",
    metricSystemImage: "figure.walk",
    metricColorHex: "#4CAF50",
    currentValue: 7500,
    targetValue: 10000,
    unitString: "steps",
    timePeriod: "daily",
    isEmpty: false
  )
}

#Preview("Inline - Steps", as: .accessoryInline) {
  WatchGoalWidget()
} timeline: {
  WatchGoalEntry(
    date: .now,
    goalId: "steps",
    metricName: "Steps",
    metricSystemImage: "figure.walk",
    metricColorHex: "#4CAF50",
    currentValue: 7500,
    targetValue: 10000,
    unitString: "steps",
    timePeriod: "daily",
    isEmpty: false
  )
}
