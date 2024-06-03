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

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        screenController.refreshActivitySelection()
        let activitySelection = screenController.activitySelection

        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = .specific(activitySelection.categoryTokens, except: [])
        store.shield.webDomains = activitySelection.webDomainTokens
        store.shield.webDomainCategories = .specific(activitySelection.categoryTokens, except: [])

        guard !screenController.hasEvents(for: activity) else { return }

        // TODO: Support action that cancels this for tonight.
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
        
        // TODO: Support action that cancels this for tonight.
        sendNotification(
            title: "Bedtime is Starting Soon",
            subtitle: "Start winding down to help reduce screentime before bed."
        )
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        guard let event = screenController.deviceActivityEvent(activityName: activity, eventName: event) else {
            return
        }

        let applications = store.shield.applications ?? []
        store.shield.applications = applications.union(event.applications)

        let webDomains = store.shield.webDomains ?? []
        store.shield.webDomains = webDomains.union(event.webDomains)

        shield(categoryTokens: event.categories)
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

    func shield(categoryTokens: Set<ActivityCategoryToken>) {
        switch store.shield.applicationCategories {
        case .all(let except):
            break // TODO: This seems problematic
        case .specific(var tokens, let exceptions):
            tokens = tokens.union(categoryTokens)
            store.shield.applicationCategories = .specific(tokens, except: exceptions)
        default:
            break
        }
        switch store.shield.webDomainCategories {
        case .all(let except):
            break // TODO: This seems problematic
        case .specific(var tokens, let exceptions):
            tokens = tokens.union(categoryTokens)
            store.shield.webDomainCategories = .specific(tokens, except: exceptions)
        default:
            break
        }
    }
}
