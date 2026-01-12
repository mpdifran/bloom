//
//  ReminderScheduler.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import Foundation
@preconcurrency import UserNotifications
import SwiftData
import DataContainer
import BloomFoundation

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
  
  /// Cleans up notifications for completed reminders (called by background tasks)
  func cleanupCompletedNotifications() async {
    do {
      let context = ModelContext(modelContainer)
      
      // Get date range for today
      let calendar = Calendar.current
      let startOfToday = calendar.startOfDay(for: Date())
      let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()
      
      // Fetch all completion records for today
      let completionDescriptor = FetchDescriptor<ReminderCompletionRecord>(
        predicate: #Predicate<ReminderCompletionRecord> { completion in
          completion.completedDate >= startOfToday &&
          completion.completedDate <= endOfToday
        }
      )
      
      let todayCompletions = try context.fetch(completionDescriptor)
      print("Background cleanup: Found \(todayCompletions.count) completions for today")
      
      if !todayCompletions.isEmpty {
        await cleanupNotificationsForCompletions(todayCompletions)
      }
      
      // Also clean up old delivered notifications
      await cleanupOldDeliveredNotifications()
      
    } catch {
      print("Background cleanup error: \(error)")
    }
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
      // Check if this occurrence has been completed today before scheduling
      if await isOccurrenceCompletedToday(reminderID: reminder.id, occurrenceID: occurrence.id) {
        print("Skipping notification scheduling for completed occurrence: \(occurrence.id)")
        continue
      }
      
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
    content.subtitle = "Reminder"
    content.sound = .default
    content.categoryIdentifier = .CategoryID.reminders
    content.threadIdentifier = reminder.id
    content.userInfo = [
      "reminderID": reminder.id,
      "occurrenceID": occurrence.id
    ]

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
        dateComponents.weekday = dayOfWeek // Already 1-based (1=Sunday, 7=Saturday)
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
    @unknown default:
      break
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
    notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
  }
  
  private func cancelAllReminderNotifications() async {
    let pendingRequests = await notificationCenter.pendingNotificationRequests()
    
    // Filter for reminder notifications (those with reminders category)
    let reminderIdentifiers = pendingRequests
      .filter { request in
        request.content.categoryIdentifier == .CategoryID.reminders
      }
      .map { $0.identifier }
    
    notificationCenter.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
  }
  
  private func isOccurrenceCompletedToday(reminderID: String, occurrenceID: String) async -> Bool {
    do {
      let context = ModelContext(modelContainer)
      
      // Get date range for today
      let calendar = Calendar.current
      let startOfToday = calendar.startOfDay(for: Date())
      let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()
      
      // Simple predicate to avoid slow type-checking from optional chaining
      let descriptor = FetchDescriptor<ReminderCompletionRecord>(
        predicate: #Predicate<ReminderCompletionRecord> { completion in
          completion.completedDate >= startOfToday &&
          completion.completedDate <= endOfToday
        }
      )

      // Fetch today's completions, then filter in-memory for the specific reminder/occurrence
      let todayCompletions = try context.fetch(descriptor)
      let matchingCompletion = todayCompletions.first { completion in
        completion.reminder?.id == reminderID && completion.occurrence?.id == occurrenceID
      }
      return matchingCompletion != nil
      
    } catch {
      print("ReminderScheduler: Error checking reminder completion: \(error)")
      return false
    }
  }
  
  private func cleanupNotificationsForCompletions(_ completions: [ReminderCompletionRecord]) async {
    let calendar = Calendar.current
    let today = Date()
    
    // Get all pending notifications
    let pendingRequests = await notificationCenter.pendingNotificationRequests()
    
    var identifiersToRemove: Set<String> = []
    
    for completion in completions {
      guard let reminderID = completion.reminder?.id,
            let occurrenceID = completion.occurrence?.id else { continue }
      
      // Find pending notifications for this completed occurrence
      for request in pendingRequests {
        guard request.content.categoryIdentifier == .CategoryID.reminders,
              let requestReminderID = request.content.userInfo["reminderID"] as? String,
              let requestOccurrenceID = request.content.userInfo["occurrenceID"] as? String,
              requestReminderID == reminderID,
              requestOccurrenceID == occurrenceID else {
          continue
        }
        
        // Check if this is today's notification
        if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger,
           let triggerDate = calendarTrigger.nextTriggerDate(),
           calendar.isDate(triggerDate, inSameDayAs: today) {
          identifiersToRemove.insert(request.identifier)
        }
      }
    }
    
    if !identifiersToRemove.isEmpty {
      notificationCenter.removePendingNotificationRequests(withIdentifiers: Array(identifiersToRemove))
      print("Background cleanup: Removed \(identifiersToRemove.count) pending notifications for completed reminders")
    }
  }
  
  private func cleanupOldDeliveredNotifications() async {
    let calendar = Calendar.current
    let today = Date()
    
    // Clean up old delivered notifications
    let deliveredNotifications = await notificationCenter.deliveredNotifications()
    let oldDeliveredIdentifiers = deliveredNotifications.compactMap { notification -> String? in
      guard !calendar.isDateInToday(notification.date) && notification.date < today else {
        return nil
      }
      return notification.request.identifier
    }
    
    if !oldDeliveredIdentifiers.isEmpty {
      notificationCenter.removeDeliveredNotifications(withIdentifiers: oldDeliveredIdentifiers)
      print("Background cleanup: Removed \(oldDeliveredIdentifiers.count) old delivered notifications")
    }
  }
}
