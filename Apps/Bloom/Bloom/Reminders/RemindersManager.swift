//
//  RemindersManager.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import Foundation
import SwiftData
import DataContainer
import UserNotifications

enum ReminderError: LocalizedError {
  case invalidConfiguration(String)
  
  var errorDescription: String? {
    switch self {
    case .invalidConfiguration(let message):
      return message
    }
  }
}

enum ReminderCompletionSource {
  case manual
  case trigger
}

@MainActor
final class RemindersManager: ObservableObject {
  static let shared = RemindersManager()
  
  private let modelActor: ReminderModelActor
  private let scheduler: ReminderScheduler
  
  @Published private(set) var reminders: [ReminderDTO] = []
  @Published private(set) var isLoading = false
  @Published private(set) var error: Error?
  
  private init() {
    self.modelActor = ReminderModelActor.standard()
    self.scheduler = ReminderScheduler.shared
  }
  
  // MARK: - Public Methods
  
  /// Fetches all reminders and updates the published array
  func fetchReminders() async {
    isLoading = true
    error = nil
    
    do {
      reminders = try await modelActor.fetchAllReminders()
    } catch {
      self.error = error
      print("Failed to fetch reminders: \(error)")
    }
    
    isLoading = false
  }
  
  /// Fetches reminders that have occurrences scheduled for today
  func fetchTodaysReminders() async throws -> [ReminderDTO] {
    return try await modelActor.fetchRemindersWithOccurrenceToday()
  }
  
  /// Creates a new reminder and schedules its notifications
  func createReminder(
    title: String,
    colorHex: String,
    triggerType: ReminderTriggerType? = nil,
    occurrences: [ReminderOccurrenceDTO],
    sideEffects: [ReminderSideEffectDTO] = []
  ) async throws -> ReminderDTO {
    let reminder = try await modelActor.createReminder(
      title: title,
      colorHex: colorHex,
      triggerType: triggerType,
      occurrences: occurrences,
      sideEffects: sideEffects
    )
    
    // Schedule notifications for the new reminder
    try await scheduler.rescheduleReminder(withID: reminder.id)
    
    // Refresh the reminders list
    await fetchReminders()

    // Sync to watch
    await WatchTodaySyncer.shared.syncToWatch()

    return reminder
  }

  /// Updates an existing reminder and reschedules its notifications
  func updateReminder(
    withID id: String,
    title: String,
    colorHex: String,
    triggerType: ReminderTriggerType? = nil,
    occurrences: [ReminderOccurrenceDTO],
    sideEffects: [ReminderSideEffectDTO] = []
  ) async throws -> ReminderDTO? {
    guard let reminder = try await modelActor.updateReminder(
      withID: id,
      title: title,
      colorHex: colorHex,
      triggerType: triggerType,
      occurrences: occurrences,
      sideEffects: sideEffects
    ) else { return nil }
    
    // Reschedule notifications for the updated reminder
    try await scheduler.rescheduleReminder(withID: reminder.id)
    
    // Refresh the reminders list
    await fetchReminders()

    // Sync to watch
    await WatchTodaySyncer.shared.syncToWatch()

    return reminder
  }

  /// Deletes a reminder and cancels its notifications
  func deleteReminder(withID id: String) async throws {
    // Cancel notifications first
    await scheduler.cancelReminder(withID: id)
    
    // Delete the reminder
    try await modelActor.deleteReminder(withID: id)

    // Refresh the reminders list
    await fetchReminders()

    // Sync to watch
    await WatchTodaySyncer.shared.syncToWatch()
  }

  /// Marks a reminder as completed for today
  func markReminderCompleted(withID id: String, occurrenceID: String? = nil, source: ReminderCompletionSource = .manual) async throws {
    let completionRecord = try await modelActor.markReminderCompleted(reminderID: id, occurrenceID: occurrenceID)
    
    // Execute side effects only for manual completions (not trigger completions)
    if source == .manual, let reminder = try await modelActor.fetchReminder(withID: id) {
      let sideEffectResults = await SideEffectExecutor.shared.executeSideEffects(for: reminder)
      
      // Store the side effect results on the completion record
      if !sideEffectResults.isEmpty, let completionRecord = completionRecord {
        try await modelActor.updateCompletionRecordWithSideEffectResults(
          completionRecordID: completionRecord.id,
          results: sideEffectResults
        )
      }
    }
    
    // Remove delivered notifications for this reminder
    await removeDeliveredNotifications(withID: id)
    
    // Remove pending notifications for the completed occurrence
    if let occurrenceID = occurrenceID {
      await removePendingNotifications(forReminderID: id, occurrenceID: occurrenceID)
    }
    
    // Refresh to update completion records
    await fetchReminders()

    // Sync to watch
    await WatchTodaySyncer.shared.syncToWatch()
  }

  /// Marks a reminder as uncompleted for today
  func markReminderUncompleted(withID id: String, occurrenceID: String? = nil) async throws {
    let sideEffectResults = try await modelActor.markReminderUncompleted(reminderID: id, occurrenceID: occurrenceID)
    
    // Undo side effects if there are any results stored
    if let results = sideEffectResults {
      await SideEffectExecutor.shared.undoSideEffects(results: results)
    }
    
    // Refresh to update completion records
    await fetchReminders()

    // Sync to watch
    await WatchTodaySyncer.shared.syncToWatch()
  }

  /// Reschedules all reminder notifications (e.g., after app launch)
  func rescheduleAllReminders() async {
    do {
      try await scheduler.rescheduleAllReminders()
    } catch {
      print("Failed to reschedule reminders: \(error)")
    }
  }
  
  // MARK: - Helper Methods
  
  /// Checks if a reminder has been completed today
  func isReminderCompletedToday(_ reminder: ReminderDTO) -> Bool {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    return reminder.completionRecords.contains { record in
      calendar.isDate(record.completedDate, inSameDayAs: today)
    }
  }
  
  /// Gets the next scheduled date for a reminder
  func nextScheduledDate(for reminder: ReminderDTO) -> Date? {
    // This would calculate the next occurrence based on the reminder's occurrences
    // Implementation depends on your specific requirements
    return nil
  }
  
  // MARK: - Private Methods
  
  /// Removes pending notifications for a specific completed occurrence
  private func removePendingNotifications(forReminderID reminderID: String, occurrenceID: String) async {
    let center = UNUserNotificationCenter.current()
    let calendar = Calendar.current
    let today = Date()
    
    // Get all pending notifications
    let pendingRequests = await center.pendingNotificationRequests()
    
    // Filter for reminder notifications from this specific reminder and occurrence
    let targetIdentifiers = pendingRequests.compactMap { request -> String? in
      // Check if it's a reminder notification with matching userInfo
      guard request.content.categoryIdentifier == .CategoryID.reminders,
            let requestReminderID = request.content.userInfo["reminderID"] as? String,
            let requestOccurrenceID = request.content.userInfo["occurrenceID"] as? String,
            requestReminderID == reminderID,
            requestOccurrenceID == occurrenceID else {
        return nil
      }
      
      // For today's completed occurrence, we want to remove the pending notification
      // Check if this is today's notification by examining the trigger
      if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
        let triggerDate = calendarTrigger.nextTriggerDate()
        if let triggerDate = triggerDate, calendar.isDate(triggerDate, inSameDayAs: today) {
          return request.identifier
        }
      }
      
      return nil
    }
    
    if !targetIdentifiers.isEmpty {
      // Remove the pending notifications for today
      center.removePendingNotificationRequests(withIdentifiers: targetIdentifiers)
      print("Removed \(targetIdentifiers.count) pending notification(s) for completed occurrence")
    }
  }
  
  /// Removes delivered notifications for a specific reminder based on today's completions
  private func removeDeliveredNotifications(withID reminderID: String) async {
    // Fetch the reminder with fresh data to get the latest completion records
    let reminder: ReminderDTO?
    do {
      reminder = try await modelActor.fetchReminder(withID: reminderID)
    } catch {
      print("Failed to fetch reminder with ID \(reminderID): \(error)")
      return
    }
    
    guard let reminder = reminder else {
      print("Could not find reminder with ID \(reminderID) to remove notifications")
      return
    }
    
    let center = UNUserNotificationCenter.current()
    let calendar = Calendar.current
    let now = Date()
    let today = calendar.startOfDay(for: now)
    
    // Get all delivered notifications
    let deliveredNotifications = await center.deliveredNotifications()
    
    // Filter for notifications from this reminder (using thread identifier)
    let reminderNotifications = deliveredNotifications.filter { notification in
      notification.request.content.threadIdentifier == reminderID &&
      notification.request.content.categoryIdentifier == .CategoryID.reminders
    }
    
    var identifiersToRemove: Set<String> = []
    
    // 1. Remove all notifications from yesterday or earlier (based on delivery date)
    for notification in reminderNotifications {
      if !calendar.isDateInToday(notification.date) && notification.date < today {
        identifiersToRemove.insert(notification.request.identifier)
      }
    }
    
    // 2. Remove notifications for today's completed occurrences
    let todaysCompletions = reminder.completionRecords
      .filter { calendar.isDate($0.completedDate, inSameDayAs: today) }
    
    // For each completed occurrence, find and remove its notification
    for completion in todaysCompletions {
      guard let occurrenceID = completion.occurrenceID else { continue }
      
      // Find the notification identifier for this occurrence
      // The identifier format should match what's used in scheduling
      let possibleIdentifiers = [
        occurrenceID, // For daily, monthly, yearly
        "\(occurrenceID)_\(calendar.component(.weekday, from: today))" // For weekly with specific day
      ]
      
      for identifier in possibleIdentifiers {
        if deliveredNotifications.contains(where: { $0.request.identifier == identifier }) {
          identifiersToRemove.insert(identifier)
        }
      }
    }
    
    // Find which of these identifiers actually have delivered notifications
    let deliveredIdentifiers = Set(reminderNotifications.map { $0.request.identifier })
    let matchingIdentifiers = identifiersToRemove.intersection(deliveredIdentifiers)
    
    if !matchingIdentifiers.isEmpty {
      // Remove the delivered notifications
      center.removeDeliveredNotifications(withIdentifiers: Array(matchingIdentifiers))
      
      let oldCount = matchingIdentifiers.filter { identifier in
        !todaysCompletions.contains { $0.occurrenceID == identifier }
      }.count
      let completedCount = matchingIdentifiers.count - oldCount
      
      if oldCount > 0 && completedCount > 0 {
        print("Removed \(oldCount) old and \(completedCount) completed notifications for '\(reminder.title)'")
      } else if oldCount > 0 {
        print("Removed \(oldCount) old notifications for '\(reminder.title)'")
      } else if completedCount > 0 {
        print("Removed \(completedCount) completed notifications for '\(reminder.title)'")
      }
    }
  }
}
