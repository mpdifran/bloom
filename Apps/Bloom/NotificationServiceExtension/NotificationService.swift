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
        let categoryID = request.content.categoryIdentifier
        guard UUID(uuidString: categoryID) != nil else {
            // Not a reminder notification (reminder IDs are UUIDs)
            return false
        }
        
        do {
            // Get the shared model container
            let container = ContainerHolder.shared.container
            let context = ModelContext(container)
            
            // Find the reminder by ID
            let descriptor = FetchDescriptor<Reminder>(
                predicate: #Predicate<Reminder> { reminder in
                    reminder.id == categoryID
                }
            )
            
            guard let reminder = try context.fetch(descriptor).first else {
                // Reminder not found, show notification
                return false
            }
            
            // Convert to DTO for easier access to completion records
            let reminderDTO = reminder.asDTO()
            
            // Check if this notification should be suppressed based on completion
            return isNotificationSuppressedByCompletion(request, reminderDTO: reminderDTO)
            
        } catch {
            // If there's an error accessing the database, show the notification to be safe
            print("NotificationService: Error checking reminder completion: \(error)")
            return false
        }
    }
    
    private func isNotificationSuppressedByCompletion(_ request: UNNotificationRequest, reminderDTO: ReminderDTO) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Parse the notification identifier to determine which occurrence this is for
        let identifier = request.identifier
        
        // Find the matching occurrence
        guard let occurrence = findOccurrenceForNotification(identifier: identifier, reminder: reminderDTO) else {
            return false
        }
        
        // Check completion records for this logical occurrence
        for completionRecord in reminderDTO.completionRecords {
            if isCompletionRelevantForNotification(
                completionDate: completionRecord.completedDate,
                notificationDate: now,
                occurrence: occurrence
            ) {
                return true // Suppress the notification
            }
        }
        
        return false // Show the notification
    }
    
    private func findOccurrenceForNotification(identifier: String, reminder: ReminderDTO) -> ReminderOccurrenceDTO? {
        // For most cadence types, identifier is just the occurrence ID
        // For weekly, it's "occurrenceID_dayOfWeek"
        
        for occurrence in reminder.occurrences {
            // Check direct match first
            if identifier == occurrence.id {
                return occurrence
            }
            
            // Check weekly format: "occurrenceID_dayOfWeek"
            if identifier.hasPrefix("\(occurrence.id)_") {
                return occurrence
            }
            
            // Check specific date format: "occurrenceID_ISO8601Date" (for non-repeating notifications)
            if identifier.hasPrefix("\(occurrence.id)_") && identifier.contains("T") {
                return occurrence
            }
        }
        
        return nil
    }
    
    private func isCompletionRelevantForNotification(
        completionDate: Date,
        notificationDate: Date,
        occurrence: ReminderOccurrenceDTO
    ) -> Bool {
        let calendar = Calendar.current
        
        switch occurrence.cadenceType {
        case .daily:
            // Completion on the same day suppresses that day's notifications
            return calendar.isDate(completionDate, inSameDayAs: notificationDate)
            
        case .weekly:
            // Completion on the same day of the week suppresses that day's notifications
            return calendar.isDate(completionDate, inSameDayAs: notificationDate)
            
        case .monthly:
            // Completion on the same day of the month in the same month suppresses notifications
            let completionComponents = calendar.dateComponents([.year, .month, .day], from: completionDate)
            let notificationComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
            
            return completionComponents.year == notificationComponents.year &&
                   completionComponents.month == notificationComponents.month &&
                   completionComponents.day == notificationComponents.day
            
        case .yearly:
            // Completion on the same day and month in the same year suppresses notifications
            let completionComponents = calendar.dateComponents([.year, .month, .day], from: completionDate)
            let notificationComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
            
            return completionComponents.year == notificationComponents.year &&
                   completionComponents.month == notificationComponents.month &&
                   completionComponents.day == notificationComponents.day
        }
    }
}
