//
//  NotificationCenterDelegate.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-12.
//

import Foundation
@preconcurrency import UserNotifications

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
        onNotificationResponse(response)
        completionHandler()
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
        default :
            return [.banner, .sound, .list]
        }
    }
}
