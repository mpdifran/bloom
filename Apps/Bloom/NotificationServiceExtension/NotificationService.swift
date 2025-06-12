//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Mark DiFranco on 2025-06-04.
//

import UserNotifications
import SwiftData
import DataContainer
import BloomFoundation

class NotificationService: UNNotificationServiceExtension {

  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    // Check if this is a reminder notification that should be suppressed
    if shouldSuppressReminderNotification(request) {
      // Suppress the notification by delivering empty content
      let emptyContent = UNMutableNotificationContent()
      contentHandler(emptyContent)
      return
    }

    // Show the notification normally
    if let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    } else {
      contentHandler(request.content)
    }
  }

  override func serviceExtensionTimeWillExpire() {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }

  // MARK: - Reminder Notification Logic

  private func shouldSuppressReminderNotification(_ request: UNNotificationRequest) -> Bool {
    // Check if this is a reminder notification by looking at the category identifier
    guard request.content.categoryIdentifier == .CategoryID.reminders else {
      // Not a reminder notification
      return false
    }

    // Extract reminder ID and occurrence ID from userInfo
    guard let reminderID = request.content.userInfo["reminderID"] as? String,
          let occurrenceID = request.content.userInfo["occurrenceID"] as? String else {
      // No IDs found in userInfo, show notification
      print("NotificationService: Missing reminderID or occurrenceID in userInfo")
      return false
    }

    do {
      // Get the shared model container
      let container = ContainerHolder.shared.container
      let context = ModelContext(container)
      
      // Get date range for today
      let calendar = Calendar.current
      let startOfToday = calendar.startOfDay(for: Date())
      let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()

      // Query for completion records matching the specific reminder, occurrence, and today's date
      let descriptor = FetchDescriptor<ReminderCompletionRecord>(
        predicate: #Predicate<ReminderCompletionRecord> { completion in
          completion.reminder?.id == reminderID &&
          completion.occurrence?.id == occurrenceID &&
          completion.completedDate >= startOfToday &&
          completion.completedDate <= endOfToday
        }
      )
      
      // Check if any completion records exist for this specific occurrence today
      let completionRecords = try context.fetch(descriptor)
      let shouldSuppress = !completionRecords.isEmpty
      
      if shouldSuppress {
        print("NotificationService: Suppressing notification for completed reminder")
      }
      
      return shouldSuppress

    } catch {
      // If there's an error accessing the database, show the notification to be safe
      print("NotificationService: Error checking reminder completion: \(error)")
      return false
    }
  }
}
