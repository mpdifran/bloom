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
  
  /// Removes delivered notifications for a specific reminder
  private func removeDeliveredNotifications(withID reminderID: String) async {
    // Find the reminder
    guard let reminder = reminders.first(where: { $0.id == reminderID }) else {
      print("Could not find reminder with ID \(reminderID) to remove notifications")
      return
    }
    
    let center = UNUserNotificationCenter.current()
    
    // Get all delivered notifications
    let deliveredNotifications = await center.deliveredNotifications()
    
    // Find notification identifiers that match this reminder
    var identifiersToRemove: [String] = []
    
    for occurrence in reminder.occurrences {
      switch occurrence.cadenceType {
      case .daily, .monthly, .yearly:
        // For these cadence types, the identifier is just the occurrence ID
        identifiersToRemove.append(occurrence.id)
        
      case .weekly:
        // For weekly reminders, check each day of the week
        if let daysOfWeek = occurrence.daysOfWeek {
          for dayOfWeek in daysOfWeek {
            identifiersToRemove.append("\(occurrence.id)_\(dayOfWeek)")
          }
        }
        
      @unknown default:
        // Handle any future cadence types
        identifiersToRemove.append(occurrence.id)
      }
    }
    
    // Filter to only identifiers that actually have delivered notifications
    let deliveredIdentifiers = Set(deliveredNotifications.map { $0.request.identifier })
    let matchingIdentifiers = identifiersToRemove.filter { deliveredIdentifiers.contains($0) }
    
    if !matchingIdentifiers.isEmpty {
      // Remove the delivered notifications
      center.removeDeliveredNotifications(withIdentifiers: matchingIdentifiers)
      print("Removed \(matchingIdentifiers.count) delivered notifications for reminder '\(reminder.title)'")
    }
  }
}
