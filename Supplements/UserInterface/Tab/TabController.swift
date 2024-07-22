//
//  TabController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import SwiftUI
import UserNotifications

enum Tab {
    case today
    case vitals
    case insights
    case actions
    case programs
    case chat
    case profile
}

@MainActor
class TabController: NSObject, ObservableObject {
    @Published var activeTab = Tab.today

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
        switch response.notification.request.content.categoryIdentifier {
        case .CategoryID.chatMessage:
            await MainActor.run {
                select(.chat)
            }
        case .CategoryID.goodMorning:
            await MainActor.run {
                select(.today)
            }
        default:
            break
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        switch notification.request.content.categoryIdentifier {
        case .CategoryID.chatMessage:
            return [.banner]
        case .CategoryID.goodMorning:
            return [.banner]
        default :
            return [.banner, .sound, .list]
        }
    }
}
