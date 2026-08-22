//
//  ReminderWidget.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-02-06.
//

import AppIntents
import BloomFoundation
import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct ReminderTimelineProvider: TimelineProvider {
  private static let remindersKey = "TodayProvider.reminders"

  func placeholder(in context: Context) -> ReminderEntry {
    .placeholder
  }

  func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
    if context.isPreview {
      completion(.placeholder)
      return
    }
    completion(makeCurrentEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
    let reminders = loadReminders()
    let uncompleted = reminders.filter { !$0.isCompleted }

    guard !uncompleted.isEmpty else {
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
      let timeline = Timeline(entries: [ReminderEntry.empty], policy: .after(nextUpdate))
      completion(timeline)
      return
    }

    let now = Date()
    var entries: [ReminderEntry] = []

    // Entry for "now"
    if let closestNow = findClosestReminder(from: uncompleted, to: now) {
      entries.append(ReminderEntry(date: now, reminder: closestNow))
    }

    // Entries at each future reminder's scheduled time so the widget auto-transitions
    let futureReminders = uncompleted
      .filter { $0.scheduledTime > now }
      .sorted { $0.scheduledTime < $1.scheduledTime }

    for futureReminder in futureReminders {
      if let closest = findClosestReminder(from: uncompleted, to: futureReminder.scheduledTime) {
        entries.append(ReminderEntry(date: futureReminder.scheduledTime, reminder: closest))
      }
    }

    // Entry 15 minutes after the last scheduled reminder (transition to overdue)
    if let lastScheduled = futureReminders.last {
      let fifteenAfter = lastScheduled.scheduledTime.addingTimeInterval(15 * 60)
      if let closest = findClosestReminder(from: uncompleted, to: fifteenAfter) {
        entries.append(ReminderEntry(date: fifteenAfter, reminder: closest))
      }
    }

    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
    let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
    completion(timeline)
  }

  // MARK: - Helpers

  private func makeCurrentEntry() -> ReminderEntry {
    let reminders = loadReminders()
    let uncompleted = reminders.filter { !$0.isCompleted }
    guard let closest = findClosestReminder(from: uncompleted, to: .now) else {
      return .empty
    }
    return ReminderEntry(date: .now, reminder: closest)
  }

  private func loadReminders() -> [WatchReminderData] {
    // Resolve the synced rules against the current time where possible, so the widget stays right
    // between syncs - including on a day the watch app hasn't been opened.
    if let slots = ReminderStore.resolvedSlots() {
      return slots.map { WatchReminderData(slot: $0) }
    }

    guard let data = UserDefaults.group.data(forKey: Self.remindersKey),
          let reminders = try? JSONDecoder.watch.decode([WatchReminderData].self, from: data) else {
      return []
    }
    return reminders
  }

  private func findClosestReminder(
    from reminders: [WatchReminderData],
    to date: Date
  ) -> WatchReminderData? {
    reminders.min {
      abs($0.scheduledTime.timeIntervalSince(date)) < abs($1.scheduledTime.timeIntervalSince(date))
    }
  }
}

// MARK: - Timeline Entry

struct ReminderEntry: TimelineEntry {
  let date: Date
  let reminder: WatchReminderData?

  var isEmpty: Bool { reminder == nil }

  var reminderColor: Color {
    guard let hex = reminder?.colorHex else { return .blue }
    return Color(hex: hex) ?? .blue
  }

  var timeText: String {
    guard let reminder else { return "" }
    // Shared short time style - follows the locale and the user's 12/24-hour setting.
    return DateFormatter.justTimeShort.string(from: reminder.scheduledTime)
  }

  var statusText: String {
    guard let reminder else { return "" }
    switch reminder.status {
    case .dueNow:
      return String(localized: "Due now", comment: "Watch reminder widget status")
    case .overdue:
      return timeText
    case .upcoming, .completed:
      return timeText
    @unknown default:
      return timeText
    }
  }

  var statusColor: Color {
    guard let reminder else { return .secondary }
    switch reminder.status {
    case .dueNow: return .orange
    case .overdue: return .red
    case .upcoming, .completed: return .secondary
    @unknown default: return .secondary
    }
  }

  static var placeholder: ReminderEntry {
    ReminderEntry(
      date: .now,
      reminder: WatchReminderData(
        reminderID: "placeholder",
        title: "Take Vitamins",
        colorHex: "#FF6B6B",
        scheduledTime: .now,
        occurrenceID: "occ",
        isCompleted: false,
        status: .dueNow
      )
    )
  }

  static var empty: ReminderEntry {
    ReminderEntry(date: .now, reminder: nil)
  }
}

// MARK: - Widget

struct ReminderWidget: Widget {
  let kind = String.WidgetKind.watchReminder

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ReminderTimelineProvider()) { entry in
      ReminderWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Reminder")
    .description("See your next upcoming reminder.")
    .supportedFamilies([.accessoryRectangular, .accessoryInline])
  }
}

// MARK: - Widget View

struct ReminderWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: ReminderEntry

  var body: some View {
    switch family {
    case .accessoryRectangular:
      RectangularReminderView(entry: entry)
    case .accessoryInline:
      InlineReminderView(entry: entry)
        .widgetURL(URL(string: "bloom://watch/today"))
    default:
      RectangularReminderView(entry: entry)
    }
  }
}

// MARK: - Rectangular View

private struct RectangularReminderView: View {
  let entry: ReminderEntry

  var body: some View {
    if let reminder = entry.reminder {
      Button(intent: CompleteReminderIntent(
        reminderID: reminder.reminderID,
        occurrenceID: reminder.occurrenceID
      )) {
        reminderContent
      }
      .buttonStyle(.plain)
    } else {
      emptyState
    }
  }

  private var reminderContent: some View {
    HStack(spacing: 8) {
      Circle()
        .stroke(entry.reminderColor, lineWidth: 2)
        .widgetAccentable()
        .frame(width: 20, height: 20)

      VStack(alignment: .leading, spacing: 2) {
        Text(entry.reminder?.title ?? "")
          .font(.system(.caption2, design: .rounded, weight: .semibold))
          .lineLimit(2)

        HStack(spacing: 4) {
          Image(systemName: "clock")
          Text(entry.statusText)
        }
        .font(.caption2)
        .foregroundStyle(entry.statusColor)
      }

      Spacer(minLength: 0)
    }
    .frame(maxHeight: .infinity)
  }

  private var emptyState: some View {
    HStack(spacing: 8) {
      Spacer(minLength: 0)
      Text("No Reminders")
      Spacer(minLength: 0)
    }
    .frame(maxHeight: .infinity)
    .font(.system(.headline, design: .rounded, weight: .semibold))
    .foregroundStyle(.secondary)
  }
}

// MARK: - Inline View

private struct InlineReminderView: View {
  let entry: ReminderEntry

  var body: some View {
    if entry.isEmpty {
      Label("No Reminders", systemImage: "bell.slash")
    } else {
      Label {
        Text("\(entry.reminder?.title ?? "") \(entry.timeText)")
      } icon: {
        Image(systemName: "circle")
      }
    }
  }
}

// MARK: - Previews

#Preview("Rectangular - Due Now", as: .accessoryRectangular) {
  ReminderWidget()
} timeline: {
  ReminderEntry(
    date: .now,
    reminder: WatchReminderData(
      reminderID: "1",
      title: "Take Vitamins",
      colorHex: "#FF6B6B",
      scheduledTime: .now,
      occurrenceID: "occ1",
      isCompleted: false,
      status: .dueNow
    )
  )
}

#Preview("Rectangular - Upcoming", as: .accessoryRectangular) {
  ReminderWidget()
} timeline: {
  ReminderEntry(
    date: .now,
    reminder: WatchReminderData(
      reminderID: "2",
      title: "Log Weight",
      colorHex: "#4ECDC4",
      scheduledTime: Date().addingTimeInterval(3600),
      occurrenceID: "occ2",
      isCompleted: false,
      status: .upcoming
    )
  )
}

#Preview("Rectangular - Overdue", as: .accessoryRectangular) {
  ReminderWidget()
} timeline: {
  ReminderEntry(
    date: .now,
    reminder: WatchReminderData(
      reminderID: "3",
      title: "Drink More Water Throughout The Day",
      colorHex: "#45B7D1",
      scheduledTime: Date().addingTimeInterval(-3600),
      occurrenceID: "occ3",
      isCompleted: false,
      status: .overdue
    )
  )
}

#Preview("Rectangular - Empty", as: .accessoryRectangular) {
  ReminderWidget()
} timeline: {
  ReminderEntry.empty
}

#Preview("Inline - Upcoming", as: .accessoryInline) {
  ReminderWidget()
} timeline: {
  ReminderEntry(
    date: .now,
    reminder: WatchReminderData(
      reminderID: "1",
      title: "Take Vitamins",
      colorHex: "#FF6B6B",
      scheduledTime: Date().addingTimeInterval(1800),
      occurrenceID: "occ1",
      isCompleted: false,
      status: .upcoming
    )
  )
}

#Preview("Inline - Empty", as: .accessoryInline) {
  ReminderWidget()
} timeline: {
  ReminderEntry.empty
}
