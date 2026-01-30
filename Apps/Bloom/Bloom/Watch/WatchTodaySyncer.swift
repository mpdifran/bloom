//
//  WatchTodaySyncer.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-30.
//

import Foundation
import BloomFoundation
import DataContainer
import SwiftData

/// Syncs today's advice and reminders to the Apple Watch
@MainActor
final class WatchTodaySyncer {
  static let shared = WatchTodaySyncer()

  private init() {}

  /// Syncs today's data to watch
  func syncToWatch() async {
    #if os(iOS)
    // Get today's advice
    let todaysAdvice = TodayInsightsManager.shared.todayContent?.todaysAdvice

    // Get today's reminders
    let reminders = await fetchTodaysReminders()

    let watchData = WatchTodayData(
      todaysAdvice: todaysAdvice,
      reminders: reminders,
      lastUpdated: Date()
    )

    guard let data = try? JSONEncoder().encode(watchData) else {
      print("Failed to encode watch data")
      return
    }

    do {
      try await WatchChannel.shared.updateApplicationContext(
        key: WatchChannel.todayDataKey,
        data: data
      )
    } catch {
      print("Failed to sync to watch: \(error)")
    }
    #endif
  }

  private func fetchTodaysReminders() async -> [WatchReminderData] {
    let context = ContainerHolder.shared.createContext()

    guard let reminders = try? context.fetchRemindersWithOccurrenceToday() else {
      return []
    }

    let now = Date()
    var watchReminders: [WatchReminderData] = []

    for reminder in reminders {
      let dto = reminder.asDTO()
      let occurrenceDisplays = dto.todaysOccurrenceDisplays()

      for display in occurrenceDisplays {
        let status = calculateStatus(
          scheduledTime: display.scheduledTime,
          isCompleted: display.isCompleted,
          now: now
        )

        let watchReminder = WatchReminderData(
          reminderID: reminder.id,
          title: reminder.title,
          colorHex: reminder.colorHex,
          scheduledTime: display.scheduledTime,
          occurrenceID: display.occurrence.id,
          isCompleted: display.isCompleted,
          status: status,
          completionDate: display.completionDate
        )
        watchReminders.append(watchReminder)
      }
    }

    // Sort to match iOS app sorting (TodayView.sortedOccurrences)
    return watchReminders.sorted { r1, r2 in
      let isCompleted1 = r1.isCompleted
      let isCompleted2 = r2.isCompleted

      // Both completed - sort by completion date (most recent first)
      if isCompleted1 && isCompleted2 {
        if let date1 = r1.completionDate, let date2 = r2.completionDate {
          return date1 > date2
        }
        // Fallback to scheduled time (most recent first)
        return r1.scheduledTime > r2.scheduledTime
      }

      // One completed, one not - uncompleted first
      if isCompleted1 != isCompleted2 {
        return !isCompleted1
      }

      // Both uncompleted - sort by status priority, then scheduled time
      let priority1 = statusPriority(r1.status)
      let priority2 = statusPriority(r2.status)

      if priority1 != priority2 {
        return priority1 < priority2
      }
      return r1.scheduledTime < r2.scheduledTime
    }
  }

  private func calculateStatus(
    scheduledTime: Date,
    isCompleted: Bool,
    now: Date
  ) -> WatchReminderStatus {
    if isCompleted {
      return .completed
    }

    let fifteenMinutesAfter = scheduledTime.addingTimeInterval(15 * 60)

    if scheduledTime <= now && now <= fifteenMinutesAfter {
      return .dueNow
    } else if fifteenMinutesAfter < now {
      return .overdue
    } else {
      return .upcoming
    }
  }

  private func statusPriority(_ status: WatchReminderStatus) -> Int {
    switch status {
    case .overdue: return 0
    case .dueNow: return 1
    case .upcoming: return 2
    case .completed: return 3
    }
  }
}
