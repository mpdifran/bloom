//
//  NotificationManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() { }
}

extension NotificationManager {

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error {
                print(error)
            }
        }
    }

    func sendNotification(title: String, subtitle: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = .default

        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: "chat-message",
                content: content,
                trigger: nil
            )
        )
    }
}
