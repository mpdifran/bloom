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

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let screenController = ScreenUseController.shared

    // MARK: Schedules

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)

        switch activity {
        case .sleep:
            // TODO: Support action that cancels this for tonight.
            sendNotification(
                title: "Bedtime is Starting Soon",
                subtitle: "Start winding down to help reduce screentime before bed."
            )
        default:
            break
        }
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        switch activity {
        case .sleep:
            setDefaultSleepShield()

            // TODO: Support action that cancels this for tonight.
            sendNotification(
                title: "It's Bedtime!",
                subtitle: "Time to put your phone down and prepare for a good sleep."
            )
        default:
            break
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        switch activity {
        case .sleep:
            store.shield.clearShield()
        case .timeExtension:
            screenController.resetTimeExtensionApps()
            setDefaultSleepShield()
        default:
            break
        }
    }

    // MARK: Events

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)

        switch activity {
        case .timeExtension:
            // TODO: Support action that extends another 15 min.
            sendNotification(
                title: "One Minute Left!",
                subtitle: "It's almost time to put your phone down and go to sleep."
            )
        default:
            break
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        switch activity {
        case .timeExtension:
            screenController.resetTimeExtensionApps()
            setDefaultSleepShield()
        default:
            break
        }
    }
}

private extension DeviceActivityMonitorExtension {

    func sendNotification(title: String, subtitle: String, includeSound: Bool = true) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        if includeSound {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().authorizeAndAdd(request)
    }

    func setDefaultSleepShield() {
        screenController.refreshActivitySelection()
        let activitySelection = screenController.activitySelection

        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = .specific(activitySelection.categoryTokens, except: [])
        store.shield.webDomains = activitySelection.webDomainTokens
        store.shield.webDomainCategories = .specific(activitySelection.categoryTokens, except: [])
    }
}
