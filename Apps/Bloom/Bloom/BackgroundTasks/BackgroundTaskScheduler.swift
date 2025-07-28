//
//  BackgroundTaskScheduler.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import BackgroundTasks

final class BackgroundTaskScheduler: Sendable {
    static let shared = BackgroundTaskScheduler()

    private init() { }
}

extension BackgroundTaskScheduler {
    
    func scheduleReminderNotificationUpdateTask() {
        let request = BGAppRefreshTaskRequest(identifier: "update-reminder-notifications")
        // Schedule to run in 4-6 hours to periodically clean up notifications
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 4, to: .now)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Reminder Notification Update Background Task Scheduled!")
        } catch(let error) {
            print("Reminder Notification Update Scheduling Error \(error.localizedDescription)")
        }
    }
    
    func updateReminderNotifications() async {
        print("Background task: Updating reminder notifications...")
        
        // Delegate to ReminderScheduler to handle all notification logic
        await ReminderScheduler.shared.cleanupCompletedNotifications()
        
        // Schedule the next background task
        scheduleReminderNotificationUpdateTask()
    }
    
    func scheduleNotificationPreferencesSyncTask() {
        let request = BGAppRefreshTaskRequest(identifier: "sync-notification-preferences")
        // Schedule to run in 12-24 hours to periodically sync preferences
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 12, to: .now)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Notification Preferences Sync Background Task Scheduled!")
        } catch(let error) {
            print("Notification Preferences Sync Scheduling Error \(error.localizedDescription)")
        }
    }
    
    func syncNotificationPreferences() async {
        print("Background task: Syncing notification preferences...")
        
        // Sync notification preferences with server
        await NotificationPreferencesService.shared.syncMorningNotificationPreferences()
        
        // Schedule the next background task
        scheduleNotificationPreferencesSyncTask()
    }
}
