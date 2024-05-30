//
//  TabController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import SwiftUI
import UserNotifications

enum Tab {
    case insights
    case chat
    case pins
    case profile
}

@MainActor
class TabController: NSObject, ObservableObject {
    @Published var activeTab = Tab.insights

    override init() {
        super.init()

        UNUserNotificationCenter.current().delegate = self
    }
}

extension TabController {

    func select(_ tab: Tab) {
        activeTab = tab
    }
}

extension TabController: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.notification.request.identifier == "chat-message" else { return }

        await MainActor.run {
            select(.chat)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        switch notification.request.identifier {
        case "chat-message":
            return []
        default :
            return [.banner, .sound, .list]
        }
    }
}
