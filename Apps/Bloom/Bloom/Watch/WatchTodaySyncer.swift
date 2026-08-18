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

    // Send the reminders themselves rather than a rendered list: the watch resolves them against
    // its own clock, so an occurrence can go from upcoming to due to overdue without a sync.
    let plans = await fetchTodaysReminderPlans()

    // Resolved occurrences for watch builds that predate reminderPlans.
    let resolved = ReminderSchedule.slots(for: plans).map { WatchReminderData(slot: $0) }

    let watchData = WatchTodayData(
      todaysAdvice: todaysAdvice,
      reminders: resolved,
      reminderPlans: plans,
      lastUpdated: Date()
    )

    guard let data = try? JSONEncoder.watch.encode(watchData) else {
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

  private func fetchTodaysReminderPlans() async -> [ReminderPlan] {
    let context = ContainerHolder.shared.createContext()

    guard let reminders = try? context.fetchRemindersWithOccurrenceToday() else {
      return []
    }

    // Only today's completions matter for what's outstanding, and they keep the payload small.
    let startOfToday = Calendar.current.startOfDay(for: Date())

    return reminders.map { $0.asDTO().asPlan(completionsSince: startOfToday) }
  }
}
