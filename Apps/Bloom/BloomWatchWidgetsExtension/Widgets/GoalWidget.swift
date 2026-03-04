//
//  GoalWidget.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-02-01.
//

import AppIntents
import BloomFoundation
import CoreHealth
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
    return .secondary
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
      return makePreviewEntry(for: configuration)
    }
    return await makeEntry(for: configuration)
  }

  func timeline(for configuration: WatchGoalWidgetIntent, in context: Context) async -> Timeline<WatchGoalEntry> {
    let entry = await makeEntry(for: configuration)

    // If empty, just refresh every 15 minutes
    guard !entry.isEmpty else {
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
      return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    // Refresh every 5 minutes to get fresh HealthKit data
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: .now) ?? .now
    return Timeline(entries: [entry], policy: .after(nextUpdate))
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

  private func makePreviewEntry(for configuration: WatchGoalWidgetIntent) -> WatchGoalEntry {
    guard let goalEntity = configuration.goal else {
      return .placeholder
    }

    let goals = loadCachedGoals()
    if let goal = goals.first(where: { $0.id == goalEntity.id }) {
      return WatchGoalEntry(
        date: .now,
        goalId: goal.id,
        metricName: goal.metricName,
        metricSystemImage: goal.metricSystemImage,
        metricColorHex: goal.metricColorHex,
        currentValue: goal.targetValue * 0.75,
        targetValue: goal.targetValue,
        unitString: goal.targetUnit,
        timePeriod: goal.timePeriod,
        isEmpty: false
      )
    }

    return WatchGoalEntry(
      date: .now,
      goalId: goalEntity.id,
      metricName: goalEntity.name,
      metricSystemImage: goalEntity.systemImage,
      metricColorHex: nil,
      currentValue: 75,
      targetValue: 100,
      unitString: "",
      timePeriod: "daily",
      isEmpty: false
    )
  }

  private func makeEntry(for configuration: WatchGoalWidgetIntent) async -> WatchGoalEntry {
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

    // Find goal data (for metadata like name, icon, target)
    guard let goal = goals.first(where: { $0.id == goalId }) else {
      return .empty
    }

    // Fetch fresh value from HealthKit directly
    let currentValue = await GoalValueFetcher.shared.fetchCurrentValue(
      goalId: goal.id,
      timePeriod: goal.timePeriod
    )

    return WatchGoalEntry(
      date: .now,
      goalId: goal.id,
      metricName: goal.metricName,
      metricSystemImage: goal.metricSystemImage,
      metricColorHex: goal.metricColorHex,
      currentValue: currentValue,
      targetValue: goal.targetValue,
      unitString: goal.targetUnit,
      timePeriod: goal.timePeriod,
      isEmpty: false
    )
  }

  private func loadCachedGoals() -> [WatchGoal] {
    guard let data = UserDefaults.group.data(forKey: Self.goalsKey),
          let goals = try? JSONDecoder.watch.decode([WatchGoal].self, from: data) else {
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
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        VStack(alignment: .leading) {
          Image(systemName: entry.metricSystemImage)
            .foregroundStyle(entry.metricColor)
            .widgetAccentable()
          Text(entry.metricName)
        }
        .font(.caption2)
        .fontWeight(.semibold)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .fixedSize(horizontal: true, vertical: false)

        Spacer()

        Text(entry.currentValue.format(using: .noDecimalPlaces))
          .font(.system(.title3, design: .rounded, weight: .bold))
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          .foregroundStyle(entry.metricColor)
          .widgetAccentable()
      }

      Spacer(minLength: 0)

      HStack(spacing: 4) {
        Gauge(value: entry.progress) { }
          .gaugeStyle(.linearCapacity)
          .tint(entry.metricColor)
          .widgetAccentable()

        Text(entry.targetValue.format(using: .noDecimalPlaces))
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }
}

// MARK: - Corner View

private struct CornerGoalView: View {
  let entry: WatchGoalEntry

  var body: some View {
    Image(systemName: entry.metricSystemImage)
      .font(.system(size: 25))
      .foregroundStyle(entry.metricColor)
      .widgetAccentable()
      .widgetLabel {
        ProgressView(value: entry.progress) {
          Text(entry.currentValue.format(using: .noDecimalPlaces))
        }
        .tint(entry.metricColor)
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

#Preview("Corner - Empty", as: .accessoryCorner) {
  WatchGoalWidget()
} timeline: {
  WatchGoalEntry.empty
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
