//
//  NotificationManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
@preconcurrency import UserNotifications
import BloomFoundation
import RevenueCat

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

  func removeAllScheduledNotifications() {
    center.removeAllPendingNotificationRequests()
  }
  
  func scheduleTrialReminderNotification(for package: Package) async {
    guard let trialReminderDate = package.trialReminderDate else { return }
    
    let content = UNMutableNotificationContent()
    content.title = "Your Free Trial Ends Soon"
    content.subtitle = "Your free trial ends in 2 days. We hope you're enjoying Bloom!"
    content.sound = .default
    content.categoryIdentifier = .CategoryID.trialReminder
    
    let dateComponents = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute],
      from: trialReminderDate
    )
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    
    let request = UNNotificationRequest(
      identifier: .NotificationID.trialReminder,
      content: content,
      trigger: trigger
    )
    
    try? await center.add(request)
  }
  
  func cancelTrialReminderNotification() async {
    center.removePendingNotificationRequests(withIdentifiers: [.NotificationID.trialReminder])
  }
}
