//
//  ReminderScheduler.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import Foundation
import UserNotifications
import SwiftData
import DataContainer

actor ReminderScheduler {
  static let shared = ReminderScheduler()
  
  private let notificationCenter = UNUserNotificationCenter.current()
  private let modelContainer: ModelContainer
  
  private init() {
    self.modelContainer = ContainerHolder.shared.container
  }
  
  /// Reschedules all reminder notifications. Call this when app launches or when reminders are edited.
  func rescheduleAllReminders() async throws {
    // Cancel all existing reminder notifications
    await cancelAllReminderNotifications()
    
    // Fetch all active reminders
    let reminders = try await fetchAllReminders()
    
    // Schedule notifications for each reminder
    for reminder in reminders {
      await scheduleNotifications(for: reminder)
    }
  }
  
  /// Reschedules notifications for a specific reminder
  func rescheduleReminder(withID reminderID: String) async throws {
    // Cancel existing notifications for this reminder
    await cancelNotifications(for: reminderID)
    
    // Fetch the specific reminder
    guard let reminder = try await fetchReminder(withID: reminderID) else { return }
    
    // Schedule new notifications
    await scheduleNotifications(for: reminder)
  }
  
  /// Cancels all notifications for a specific reminder
  func cancelReminder(withID reminderID: String) async {
    await cancelNotifications(for: reminderID)
  }
  
  // MARK: - Private Methods
  
  private func fetchAllReminders() async throws -> [ReminderDTO] {
    let context = ModelContext(modelContainer)
    let descriptor = FetchDescriptor<Reminder>()
    let reminders = try context.fetch(descriptor)
    return reminders.map { $0.asDTO() }
  }
  
  private func fetchReminder(withID id: String) async throws -> ReminderDTO? {
    let context = ModelContext(modelContainer)
    let descriptor = FetchDescriptor<Reminder>(
      predicate: #Predicate<Reminder> { reminder in
        reminder.id == id
      }
    )
    let reminders = try context.fetch(descriptor)
    return reminders.first?.asDTO()
  }
  
  private func scheduleNotifications(for reminder: ReminderDTO) async {
    for occurrence in reminder.occurrences {
      let notifications = createNotificationRequests(
        for: reminder,
        occurrence: occurrence
      )
      
      for notification in notifications {
        do {
          try await notificationCenter.add(notification)
        } catch {
          print("Failed to schedule notification for reminder \(reminder.id): \(error)")
        }
      }
    }
  }
  
  private func createNotificationRequests(
    for reminder: ReminderDTO,
    occurrence: ReminderOccurrenceDTO
  ) -> [UNNotificationRequest] {
    var requests: [UNNotificationRequest] = []
    
    let content = UNMutableNotificationContent()
    content.title = reminder.title
    content.sound = .default
    content.categoryIdentifier = reminder.id
    
    // Convert timeOfDay (seconds since midnight) to date components
    let hour = Int(occurrence.timeOfDay) / 3600
    let minute = (Int(occurrence.timeOfDay) % 3600) / 60
    
    switch occurrence.cadenceType {
    case .daily:
      var dateComponents = DateComponents()
      dateComponents.hour = hour
      dateComponents.minute = minute
      
      let trigger = UNCalendarNotificationTrigger(
        dateMatching: dateComponents,
        repeats: true
      )
      
      let request = UNNotificationRequest(
        identifier: occurrence.id,
        content: content,
        trigger: trigger
      )
      requests.append(request)
      
    case .weekly:
      // Schedule a notification for each selected day of the week
      guard let daysOfWeek = occurrence.daysOfWeek, !daysOfWeek.isEmpty else {
        return []
      }
      
      for dayOfWeek in daysOfWeek {
        var dateComponents = DateComponents()
        dateComponents.weekday = dayOfWeek + 1 // Convert 0-based to 1-based
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
          dateMatching: dateComponents,
          repeats: true
        )
        
        // Create unique identifier for each day
        let request = UNNotificationRequest(
          identifier: "\(occurrence.id)_\(dayOfWeek)",
          content: content,
          trigger: trigger
        )
        requests.append(request)
      }
      
    case .monthly:
      guard let dayOfMonth = occurrence.dayOfMonth else { return [] }
      
      var dateComponents = DateComponents()
      dateComponents.day = dayOfMonth
      dateComponents.hour = hour
      dateComponents.minute = minute
      
      let trigger = UNCalendarNotificationTrigger(
        dateMatching: dateComponents,
        repeats: true
      )
      
      let request = UNNotificationRequest(
        identifier: occurrence.id,
        content: content,
        trigger: trigger
      )
      requests.append(request)
      
    case .yearly:
      guard let monthOfYear = occurrence.monthOfYear,
            let dayOfYear = occurrence.dayOfYear else { return [] }
      
      var dateComponents = DateComponents()
      dateComponents.month = monthOfYear
      dateComponents.day = dayOfYear
      dateComponents.hour = hour
      dateComponents.minute = minute
      
      let trigger = UNCalendarNotificationTrigger(
        dateMatching: dateComponents,
        repeats: true
      )
      
      let request = UNNotificationRequest(
        identifier: occurrence.id,
        content: content,
        trigger: trigger
      )
      requests.append(request)
    }
    
    return requests
  }
  
  private func cancelNotifications(for reminderID: String) async {
    // Fetch the reminder to get its occurrence IDs
    guard let reminder = try? await fetchReminder(withID: reminderID) else { return }
    
    var identifiersToRemove: [String] = []
    
    for occurrence in reminder.occurrences {
      switch occurrence.cadenceType {
      case .weekly:
        // For weekly reminders, we need to remove all day-specific identifiers
        if let daysOfWeek = occurrence.daysOfWeek {
          for dayOfWeek in daysOfWeek {
            identifiersToRemove.append("\(occurrence.id)_\(dayOfWeek)")
          }
        }
      default:
        // For other cadence types, just use the occurrence ID
        identifiersToRemove.append(occurrence.id)
      }
    }
    
    notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
  }
  
  private func cancelAllReminderNotifications() async {
    let pendingRequests = await notificationCenter.pendingNotificationRequests()
    
    // Filter for reminder notifications (those with UUID-like category identifiers)
    let reminderIdentifiers = pendingRequests
      .filter { request in
        // Check if category identifier looks like a UUID (reminder ID)
        let categoryID = request.content.categoryIdentifier
        return UUID(uuidString: categoryID) != nil
      }
      .map { $0.identifier }
    
    notificationCenter.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
  }
}