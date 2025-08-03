//
//  NotificationCenterDelegate.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-12.
//

import Foundation
@preconcurrency import UserNotifications
import SwiftData
import DataContainer
import BloomFoundation

final class NotificationCenterDelegate: NSObject {

    private let onNotificationResponse: ((UNNotificationResponse) -> Void)

    init(onNotificationResponse: @escaping (UNNotificationResponse) -> Void) {
        self.onNotificationResponse = onNotificationResponse

        super.init()

        UNUserNotificationCenter.current().delegate = self
    }
}

extension NotificationCenterDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification actions
        Task {
            await handleNotificationAction(response)
            onNotificationResponse(response)
            completionHandler()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        switch notification.request.content.categoryIdentifier {
        case .CategoryID.chatMessage:
            return [.banner]
        case .CategoryID.goodMorning, .CategoryID.goodEvening:
            return [.banner]
        case .CategoryID.reviewFocusAreas:
            return [.banner]
        case .CategoryID.reminders:
            // Check if this reminder has been completed
            if await isReminderCompleted(notification: notification) {
                // Don't show notification for completed reminders
                return []
            }
            return [.banner, .sound, .list]
        default: 
            return [.banner, .sound, .list]
        }
    }
    
    // MARK: - Private Methods
    
    private func handleNotificationAction(_ response: UNNotificationResponse) async {
        guard response.notification.request.content.categoryIdentifier == .CategoryID.reminders else {
            return
        }
        
        switch response.actionIdentifier {
        case .ActionID.completeReminder:
            await handleCompleteReminderAction(response.notification)
        default:
            break
        }
    }
    
    private func handleCompleteReminderAction(_ notification: UNNotification) async {
        guard let reminderID = notification.request.content.userInfo["reminderID"] as? String,
              let occurrenceID = notification.request.content.userInfo["occurrenceID"] as? String else {
            print("NotificationCenterDelegate: Missing reminderID or occurrenceID in notification userInfo")
            return
        }
        
        do {
            try await RemindersManager.shared.markReminderCompleted(withID: reminderID, occurrenceID: occurrenceID)
            print("NotificationCenterDelegate: Successfully completed reminder \(reminderID)")
        } catch {
            print("NotificationCenterDelegate: Failed to complete reminder \(reminderID): \(error)")
        }
    }
    
    private func isReminderCompleted(notification: UNNotification) async -> Bool {
        // Extract reminder ID and occurrence ID from userInfo
        guard let reminderID = notification.request.content.userInfo["reminderID"] as? String,
              let occurrenceID = notification.request.content.userInfo["occurrenceID"] as? String else {
            // If we can't get IDs, show the notification to be safe
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
                    completion.reminder?.id == reminderID && completion.occurrence?.id == occurrenceID && completion.completedDate >= startOfToday && completion.completedDate <= endOfToday
                }
            )
            
            // Check if any completion records exist for this specific occurrence today
            let completionRecords = try context.fetch(descriptor)
            return !completionRecords.isEmpty
            
        } catch {
            // If there's an error accessing the database, show the notification to be safe
            print("NotificationCenterDelegate: Error checking reminder completion: \(error)")
            return false
        }
    }
}
