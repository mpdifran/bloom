//
//  TodayProvider.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-30.
//

import Foundation
import BloomFoundation

/// Provides today's advice and reminders data on watchOS by reading from WatchConnectivity application context.
@Observable @MainActor
public final class TodayProvider {
  public static let shared = TodayProvider()

  private static let adviceKey = "TodayProvider.advice"
  private static let remindersKey = "TodayProvider.reminders"
  private static let lastUpdatedKey = "TodayProvider.lastUpdated"

  public private(set) var todaysAdvice: String? {
    didSet { saveToUserDefaults() }
  }

  public private(set) var reminders: [WatchReminderData] = [] {
    didSet { saveToUserDefaults() }
  }

  public private(set) var lastUpdated: Date? {
    didSet { saveToUserDefaults() }
  }

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
          let watchData = try? JSONDecoder().decode(WatchTodayData.self, from: data) else {
      return
    }

    todaysAdvice = watchData.todaysAdvice
    reminders = watchData.reminders
    lastUpdated = watchData.lastUpdated
  }

  private func loadFromUserDefaults() {
    todaysAdvice = UserDefaults.group.string(forKey: Self.adviceKey)

    if let remindersData = UserDefaults.group.data(forKey: Self.remindersKey) {
      do {
        reminders = try JSONDecoder().decode([WatchReminderData].self, from: remindersData)
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
  }

  private func saveToUserDefaults() {
    if let advice = todaysAdvice {
      UserDefaults.group.set(advice, forKey: Self.adviceKey)
    } else {
      UserDefaults.group.removeObject(forKey: Self.adviceKey)
    }

    if let data = try? JSONEncoder().encode(reminders) {
      UserDefaults.group.set(data, forKey: Self.remindersKey)
    }

    if let lastUpdated {
      UserDefaults.group.set(lastUpdated.timeIntervalSince1970, forKey: Self.lastUpdatedKey)
    }
  }

  /// Updates a reminder's completion status optimistically (before phone confirms)
  func updateReminderOptimistically(reminderID: String, occurrenceID: String, isCompleted: Bool) {
    guard let index = reminders.firstIndex(where: {
      $0.reminderID == reminderID && $0.occurrenceID == occurrenceID
    }) else { return }

    let newStatus: WatchReminderStatus = isCompleted ? .completed : calculateUncompleteStatus(for: reminders[index])

    reminders[index].isCompleted = isCompleted
    reminders[index].status = newStatus
  }

  private func calculateUncompleteStatus(for reminder: WatchReminderData) -> WatchReminderStatus {
    let now = Date()
    let fifteenMinutesAfter = reminder.scheduledTime.addingTimeInterval(15 * 60)

    if reminder.scheduledTime <= now && now <= fifteenMinutesAfter {
      return .dueNow
    } else if fifteenMinutesAfter < now {
      return .overdue
    } else {
      return .upcoming
    }
  }
}
