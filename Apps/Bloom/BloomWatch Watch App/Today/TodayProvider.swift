//
//  TodayProvider.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-30.
//

import Foundation
import BloomFoundation
import WidgetKit

/// Provides today's advice and reminders data on watchOS by reading from WatchConnectivity application context.
///
/// The phone syncs reminder rules, not a rendered list, so this resolves them locally: the same
/// `ReminderSchedule` the iOS app uses decides what shows and whether it's upcoming, due or overdue.
/// That keeps the watch correct as the clock moves - including across midnight - without a sync.
@Observable @MainActor
public final class TodayProvider {
  public static let shared = TodayProvider()

  private static let adviceKey = "TodayProvider.advice"
  private static let remindersKey = "TodayProvider.reminders"
  private static let lastUpdatedKey = "TodayProvider.lastUpdated"

  public private(set) var todaysAdvice: String? {
    didSet { saveToUserDefaults() }
  }

  /// Today's occurrences, resolved as of the last `refresh()`.
  public private(set) var reminders: [WatchReminderData] = [] {
    didSet { saveToUserDefaults() }
  }

  public private(set) var lastUpdated: Date? {
    didSet { saveToUserDefaults() }
  }

  /// The reminder rules the phone last sent, or nil if it has never sent any (older phone build).
  private var plans: [ReminderPlan]?

  /// Completions made on this watch that the phone hasn't echoed back yet.
  private var overrides: [ReminderCompletionOverride] = []

  public var hasContent: Bool {
    reminders.isNotEmpty
  }

  private init() {
    loadFromUserDefaults()
    loadFromApplicationContext()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleApplicationContextUpdate),
      name: WatchChannel.applicationContextDidUpdate,
      object: nil
    )
  }

  @objc private func handleApplicationContextUpdate() {
    loadFromApplicationContext()
  }

  /// Loads today's data from WatchConnectivity application context
  public func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.todayDataKey),
          let watchData = try? JSONDecoder.watch.decode(WatchTodayData.self, from: data) else {
      // Still re-resolve: statuses move on even when no new data arrives.
      refresh()
      return
    }

    todaysAdvice = watchData.todaysAdvice
    lastUpdated = watchData.lastUpdated

    guard let plans = watchData.reminderPlans else {
      // Phone app predates reminder plans - fall back to its resolved list.
      self.plans = nil
      ReminderStore.savePlans(nil)
      reminders = watchData.reminders
      return
    }

    self.plans = plans
    ReminderStore.savePlans(plans)
    reconcileOverrides(against: plans, sentAt: watchData.lastUpdated)
    refresh()
  }

  /// Re-resolves today's occurrences against the current time.
  public func refresh() {
    guard let plans else { return }

    // The widget completes reminders too, straight into the shared store.
    overrides = ReminderStore.loadOverrides()

    let resolved = ReminderSchedule.applying(overrides, to: plans)
    let slots = ReminderSchedule.slots(for: resolved).map(WatchReminderData.init(slot:))

    // Only assign on a real change: this runs on a timer, and every write reloads widget timelines.
    guard slots != reminders else { return }

    reminders = slots
  }

  /// Drops local completions the phone has caught up with.
  ///
  /// An override is only retired once the phone's own data agrees with it - a sync built before the
  /// completion message landed is newer in time but doesn't know about it yet, and dropping the
  /// override there would flash the row back to uncompleted.
  private func reconcileOverrides(against plans: [ReminderPlan], sentAt: Date) {
    let calendar = Calendar.current
    let now = Date()

    overrides = ReminderStore.loadOverrides().filter { override in
      // Completions are day-scoped, so yesterday's override can never apply again.
      guard calendar.isDate(override.date, inSameDayAs: now) else { return false }
      guard override.date < sentAt else { return true }

      let plan = plans.first { $0.id == override.reminderID }
      let phoneSaysCompleted = plan?.completions.contains { $0.occurrenceID == override.occurrenceID } ?? false

      return phoneSaysCompleted != override.isCompleted
    }

    ReminderStore.saveOverrides(overrides)
  }

  private func loadFromUserDefaults() {
    todaysAdvice = UserDefaults.group.string(forKey: Self.adviceKey)
    plans = ReminderStore.loadPlans()
    overrides = ReminderStore.loadOverrides()

    if let remindersData = UserDefaults.group.data(forKey: Self.remindersKey) {
      do {
        reminders = try JSONDecoder.watch.decode([WatchReminderData].self, from: remindersData)
      } catch {
        // Clear corrupted data so fresh sync can succeed
        print("Failed to decode reminders, clearing cache: \(error)")
        UserDefaults.group.removeObject(forKey: Self.remindersKey)
        reminders = []
      }
    }

    if let timestamp = UserDefaults.group.object(forKey: Self.lastUpdatedKey) as? Double {
      lastUpdated = Date(timeIntervalSince1970: timestamp)
    }

    refresh()
  }

  private func saveToUserDefaults() {
    if let advice = todaysAdvice {
      UserDefaults.group.set(advice, forKey: Self.adviceKey)
    } else {
      UserDefaults.group.removeObject(forKey: Self.adviceKey)
    }

    if let data = try? JSONEncoder.watch.encode(reminders) {
      UserDefaults.group.set(data, forKey: Self.remindersKey)
    }

    if let lastUpdated {
      UserDefaults.group.set(lastUpdated.timeIntervalSince1970, forKey: Self.lastUpdatedKey)
    }

    WidgetCenter.shared.reloadTimelines(ofKind: String.WidgetKind.watchReminder)
  }

  /// Records a completion made on this watch, before the phone confirms it.
  ///
  /// The override survives re-resolution and app restarts, and is dropped once the phone sends
  /// reminder data that agrees with it.
  func updateReminderOptimistically(reminderID: String, occurrenceID: String, isCompleted: Bool) {
    ReminderStore.addOverride(ReminderCompletionOverride(
      reminderID: reminderID,
      occurrenceID: occurrenceID,
      isCompleted: isCompleted,
      date: Date()
    ))

    guard plans != nil else {
      // No rules to resolve (older phone build) - fall back to editing the rendered list.
      guard let index = reminders.firstIndex(where: {
        $0.reminderID == reminderID && $0.occurrenceID == occurrenceID
      }) else { return }

      reminders[index].isCompleted = isCompleted
      reminders[index].status = ReminderSchedule.status(
        scheduledTime: reminders[index].scheduledTime,
        isCompleted: isCompleted,
        now: Date()
      )
      return
    }

    refresh()
  }
}
