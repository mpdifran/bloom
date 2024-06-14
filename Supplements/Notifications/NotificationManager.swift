//
//  NotificationManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import UserNotifications

extension String {
    enum NotificationID {
        static let goodMorning = "good-morning"
    }
}

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
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
        )
    }

    func sendGoodMorningNotification(delay: TimeInterval? = nil) async {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.subtitle = "Check out how your sleep was last night."
        content.sound = .default

        let trigger: UNNotificationTrigger?
        if let delay {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = nil
        }

        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: .NotificationID.goodMorning,
                content: content,
                trigger: trigger
            )
        )
    }
}
