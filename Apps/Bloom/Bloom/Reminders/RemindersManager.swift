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
    occurrences: [ReminderOccurrence]
  ) async throws -> ReminderDTO {
    let reminder = try await modelActor.createReminder(
      title: title,
      colorHex: colorHex,
      occurrences: occurrences
    )
    
    // Schedule notifications for the new reminder
    try await scheduler.rescheduleReminder(withID: reminder.id)
    
    // Refresh the reminders list
    await fetchReminders()
    
    return reminder
  }
  
  /// Updates an existing reminder and reschedules its notifications
  func updateReminder(
    withID id: String,
    title: String,
    colorHex: String,
    occurrences: [ReminderOccurrence]
  ) async throws -> ReminderDTO? {
    guard let reminder = try await modelActor.updateReminder(
      withID: id,
      title: title,
      colorHex: colorHex,
      occurrences: occurrences
    ) else { return nil }
    
    // Reschedule notifications for the updated reminder
    try await scheduler.rescheduleReminder(withID: reminder.id)
    
    // Refresh the reminders list
    await fetchReminders()
    
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
  }
  
  /// Marks a reminder as completed for today
  func markReminderCompleted(withID id: String, occurrenceID: String? = nil) async throws {
    _ = try await modelActor.markReminderCompleted(reminderID: id, occurrenceID: occurrenceID)
    
    // Remove delivered notifications for this reminder
    await removeDeliveredNotifications(withID: id)
    
    // Refresh to update completion records
    await fetchReminders()
  }
  
  /// Marks a reminder as uncompleted for today
  func markReminderUncompleted(withID id: String, occurrenceID: String? = nil) async throws {
    try await modelActor.markReminderUncompleted(reminderID: id, occurrenceID: occurrenceID)
    
    // Refresh to update completion records
    await fetchReminders()
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
