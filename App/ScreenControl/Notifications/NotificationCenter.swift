//
//  NotificationCenter.swift
//  ScreenControl
//
//  Created by Mark DiFranco on 2024-06-03.
//

import Foundation
import UserNotifications

public extension UNUserNotificationCenter {

    func authorizeAndAdd(_ request: UNNotificationRequest) {
        requestAuthorization { [weak self] in
            self?.add(request)
        }
    }
}

private extension UNUserNotificationCenter {

    func requestAuthorization(_ completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            completion()
        }
    }
}
