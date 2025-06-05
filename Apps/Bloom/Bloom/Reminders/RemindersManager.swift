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
  func markReminderCompleted(withID id: String) async throws {
    _ = try await modelActor.markReminderCompleted(reminderID: id)
    
    // Remove delivered notifications for this reminder
    await removeDeliveredNotifications(withID: id)
    
    // Refresh to update completion records
    await fetchReminders()
  }
  
  /// Marks a reminder as uncompleted for today
  func markReminderUncompleted(withID id: String) async throws {
    try await modelActor.markReminderUncompleted(reminderID: id)
    
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
      .sorted { $0.completedDate < $1.completedDate }
    
    // Get all occurrences scheduled for today with their times
    var occurrenceTimePairs: [(occurrence: ReminderOccurrenceDTO, scheduledTime: Date, identifier: String)] = []
    
    for occurrence in reminder.occurrences {
      let scheduledTimes = getScheduledTimesToday(for: occurrence, calendar: calendar, today: today)
      for (scheduledTime, identifier) in scheduledTimes {
        occurrenceTimePairs.append((occurrence, scheduledTime, identifier))
      }
    }
    
    // Sort by scheduled time
    occurrenceTimePairs.sort { $0.scheduledTime < $1.scheduledTime }
    
    // Add identifiers for completed occurrences
    let completedIdentifiers = occurrenceTimePairs
      .prefix(todaysCompletions.count)
      .map { $0.identifier }
    
    for identifier in completedIdentifiers {
      identifiersToRemove.insert(identifier)
    }
    
    // Find which of these identifiers actually have delivered notifications
    let deliveredIdentifiers = Set(reminderNotifications.map { $0.request.identifier })
    let matchingIdentifiers = identifiersToRemove.intersection(deliveredIdentifiers)
    
    if !matchingIdentifiers.isEmpty {
      // Remove the delivered notifications
      center.removeDeliveredNotifications(withIdentifiers: Array(matchingIdentifiers))
      
      let oldCount = identifiersToRemove.subtracting(Set(completedIdentifiers)).count
      let completedCount = matchingIdentifiers.intersection(Set(completedIdentifiers)).count
      
      if oldCount > 0 && completedCount > 0 {
        print("Removed \(oldCount) old and \(completedCount) completed notifications for '\(reminder.title)'")
      } else if oldCount > 0 {
        print("Removed \(oldCount) old notifications for '\(reminder.title)'")
      } else if completedCount > 0 {
        print("Removed \(completedCount) completed notifications for '\(reminder.title)'")
      }
    }
  }
  
  /// Helper method to get scheduled times and identifiers for an occurrence today
  private func getScheduledTimesToday(
    for occurrence: ReminderOccurrenceDTO,
    calendar: Calendar,
    today: Date
  ) -> [(Date, String)] {
    let hour = Int(occurrence.timeOfDay) / 3600
    let minute = (Int(occurrence.timeOfDay) % 3600) / 60
    
    switch occurrence.cadenceType {
    case .daily:
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
        return [(scheduledTime, occurrence.id)]
      }
      
    case .weekly:
      // Check if today is one of the scheduled days
      guard let daysOfWeek = occurrence.daysOfWeek,
            let todayWeekday = calendar.dateComponents([.weekday], from: Date()).weekday,
            daysOfWeek.contains(todayWeekday) else {
        return []
      }
      
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
        return [(scheduledTime, "\(occurrence.id)_\(todayWeekday)")]
      }
      
    case .monthly:
      // Check if today is the scheduled day of month
      guard let dayOfMonth = occurrence.dayOfMonth,
            let todayDay = calendar.dateComponents([.day], from: Date()).day,
            dayOfMonth == todayDay else {
        return []
      }
      
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
        return [(scheduledTime, occurrence.id)]
      }
      
    case .yearly:
      // Check if today is the scheduled month and day
      guard let monthOfYear = occurrence.monthOfYear,
            let dayOfYear = occurrence.dayOfYear else {
        return []
      }
      
      let todayComponents = calendar.dateComponents([.month, .day], from: Date())
      guard monthOfYear == todayComponents.month,
            dayOfYear == todayComponents.day else {
        return []
      }
      
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
        return [(scheduledTime, occurrence.id)]
      }
      
    @unknown default:
      return []
    }
    
    return []
  }
}
