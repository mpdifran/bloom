//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Created by Mark DiFranco on 2024-06-01.
//

import DeviceActivity
import ManagedSettings
import ScreenControl
import UserNotifications

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let screenController = ScreenUseController.shared

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        screenController.refreshActivitySelection()

        store.shield.applications = screenController.activitySelection.applicationTokens
        store.shield.applicationCategories = .specific(screenController.activitySelection.categoryTokens, except: [])

        sendNotification(
            title: "It's Bedtime!",
            subtitle: "Time to put your phone down and prepare for a good sleep."
        )
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        sendNotification(
            title: "Bedtime is Starting Soon",
            subtitle: "Start winding down to help reduce screentime before bed."
        )
    }
}

private extension DeviceActivityMonitorExtension {

    func requestAuthorization(_ completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            completion()
        }
    }

    func sendNotification(title: String, subtitle: String) {
        requestAuthorization {
            let content = UNMutableNotificationContent()
            content.title = title
            content.subtitle = subtitle
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )

            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }
}
