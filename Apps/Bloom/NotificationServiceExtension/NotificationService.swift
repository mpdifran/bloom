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
        
        // Get the reminder ID from the thread identifier
        let reminderID = request.content.threadIdentifier
        guard !reminderID.isEmpty else {
            // No reminder ID found
            return false
        }
        
        do {
            // Get the shared model container
            let container = ContainerHolder.shared.container
            let context = ModelContext(container)
            
            // Find the reminder by ID
            let descriptor = FetchDescriptor<Reminder>(
                predicate: #Predicate<Reminder> { reminder in
                    reminder.id == reminderID
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
        let today = calendar.startOfDay(for: now)
        
        // Get today's completion records sorted by completion time
        let todaysCompletions = reminderDTO.completionRecords
            .filter { calendar.isDate($0.completedDate, inSameDayAs: today) }
            .sorted { $0.completedDate < $1.completedDate }
        
        // Get all occurrences scheduled for today with their times
        var occurrenceTimePairs: [(ReminderOccurrenceDTO, Date)] = []
        
        for occurrence in reminderDTO.occurrences {
            let scheduledTimes = getScheduledTimesToday(for: occurrence)
            for scheduledTime in scheduledTimes {
                occurrenceTimePairs.append((occurrence, scheduledTime))
            }
        }
        
        // Sort by scheduled time
        occurrenceTimePairs.sort { $0.1 < $1.1 }
        
        // Find which occurrence index this notification represents
        let identifier = request.identifier
        guard let notificationOccurrence = findOccurrenceForNotification(identifier: identifier, reminder: reminderDTO),
              let occurrenceIndex = occurrenceTimePairs.firstIndex(where: { 
                  $0.0.id == notificationOccurrence.id 
              }) else {
            return false
        }
        
        // Check if this occurrence is covered by completions
        // Completions cover occurrences in chronological order
        return occurrenceIndex < todaysCompletions.count
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
    
    private func getScheduledTimesToday(for occurrence: ReminderOccurrenceDTO) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        switch occurrence.cadenceType {
        case .daily:
            // Daily reminders occur once per day at the specified time
            let hour = Int(occurrence.timeOfDay) / 3600
            let minute = (Int(occurrence.timeOfDay) % 3600) / 60
            
            if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
                return [scheduledTime]
            }
            return []
            
        case .weekly:
            // Check if today is one of the scheduled days
            guard let daysOfWeek = occurrence.daysOfWeek,
                  let todayWeekday = calendar.dateComponents([.weekday], from: now).weekday,
                  daysOfWeek.contains(todayWeekday) else {
                return []
            }
            
            let hour = Int(occurrence.timeOfDay) / 3600
            let minute = (Int(occurrence.timeOfDay) % 3600) / 60
            
            if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
                return [scheduledTime]
            }
            return []
            
        case .monthly:
            // Check if today is the scheduled day of month
            guard let dayOfMonth = occurrence.dayOfMonth,
                  let todayDay = calendar.dateComponents([.day], from: now).day,
                  dayOfMonth == todayDay else {
                return []
            }
            
            let hour = Int(occurrence.timeOfDay) / 3600
            let minute = (Int(occurrence.timeOfDay) % 3600) / 60
            
            if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
                return [scheduledTime]
            }
            return []
            
        case .yearly:
            // Check if today is the scheduled month and day
            guard let monthOfYear = occurrence.monthOfYear,
                  let dayOfYear = occurrence.dayOfYear else {
                return []
            }
            
            let todayComponents = calendar.dateComponents([.month, .day], from: now)
            guard monthOfYear == todayComponents.month,
                  dayOfYear == todayComponents.day else {
                return []
            }
            
            let hour = Int(occurrence.timeOfDay) / 3600
            let minute = (Int(occurrence.timeOfDay) % 3600) / 60
            
            if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
                return [scheduledTime]
            }
            return []
        }
    }
}
