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
    static let goodEvening = "good-evening"
    static let reviewFocusAreas = "review-focus-areas"
  }
  enum CategoryID {
    static let goodMorning = "good-morning"
    static let goodEvening = "good-evening"
    static let reviewFocusAreas = "review-focus-areas"
    static let chatMessage = "chat-message"
    static let goalsMessage = "goals-message"
  }
}

final class NotificationManager: Sendable {
  static let shared = NotificationManager()

  private init() { }

  private let center = UNUserNotificationCenter.current()
}

extension NotificationManager {

  func requestAuthorization() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
      if let error {
        print(error)
      }
    }
  }

  func shouldRequestAuthorization() async -> Bool {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    return settings.authorizationStatus == .notDetermined
  }

  func sendNotification(title: String, subtitle: String, categoryID: String? = nil) async {
    let content = UNMutableNotificationContent()
    content.title = title
    content.subtitle = subtitle
    content.sound = .default
    if let categoryID {
      content.categoryIdentifier = categoryID
    }

    try? await UNUserNotificationCenter.current().add(
      UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil
      )
    )
  }

  func sendGoodMorningNotification(
    message: String?,
    delay: TimeInterval? = nil
  ) async {
    let content = UNMutableNotificationContent()
    content.title = "Morning Report"
    content.subtitle = message ?? "Check out your personalized report for today."
    content.sound = .default
    content.categoryIdentifier = .CategoryID.goodMorning

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

  func removeAllScheduledNotifications() {
    center.removeAllPendingNotificationRequests()
  }
}
