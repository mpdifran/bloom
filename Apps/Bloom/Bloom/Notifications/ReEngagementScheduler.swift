//
//  ReEngagementScheduler.swift
//  Bloom
//
//  Created by Claude on 2025-02-06.
//

import Foundation
@preconcurrency import UserNotifications
import SwiftUI
import BloomFoundation

actor ReEngagementScheduler {
  static let shared = ReEngagementScheduler()

  private let notificationCenter = UNUserNotificationCenter.current()

  private init() {}

  /// Schedules or cancels re-engagement notification based on onboarding status
  @MainActor
  func scheduleNotificationIfNeeded() async {
    // Check if onboarding is complete
    @AppStorage("hasShownOnboardingV3") var hasShownOnboarding: Bool = false

    print("[Re-Engagement] scheduleNotificationIfNeeded() called")
    print("[Re-Engagement] hasShownOnboardingV3: \(hasShownOnboarding)")

    if hasShownOnboarding {
      // Onboarding complete - cancel any pending notifications
      print("[Re-Engagement] Onboarding complete, cancelling notifications")
      await cancelNotification()
    } else {
      // Onboarding not complete - request auth first, then schedule notification
      print("[Re-Engagement] Onboarding not complete, requesting auth and scheduling notification")

      // Request provisional authorization BEFORE scheduling
      await requestProvisionalAuthIfNeeded()

      // Now schedule notification for 1 day from now
      await scheduleNotification()
    }
  }

  /// Cancels the re-engagement notification
  func cancelNotification() async {
    notificationCenter.removePendingNotificationRequests(withIdentifiers: [.NotificationID.reEngagement])
    notificationCenter.removeDeliveredNotifications(withIdentifiers: [.NotificationID.reEngagement])
    print("[Re-Engagement] Cancelled notification")
  }

  // MARK: - Private Methods

  private func scheduleNotification() async {
    // Calculate trigger date: 1 day from now (or minutes in test mode) at 11am
    guard let triggerDate = calculateTriggerDate() else {
      print("[Re-Engagement] Failed to calculate trigger date")
      return
    }

    let content = createNotificationContent()

    let dateComponents = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute],
      from: triggerDate
    )

    let trigger = UNCalendarNotificationTrigger(
      dateMatching: dateComponents,
      repeats: false
    )

    let request = UNNotificationRequest(
      identifier: .NotificationID.reEngagement,
      content: content,
      trigger: trigger
    )

    do {
      try await notificationCenter.add(request)
      print("[Re-Engagement] Scheduled notification for \(triggerDate)")

      #if DEBUG
      await logPendingNotifications()
      #endif
    } catch {
      print("[Re-Engagement] Failed to schedule notification: \(error)")
    }
  }

  private var isTestModeEnabled: Bool {
    #if DEBUG
    return true  // Always use minutes in DEBUG builds for easier testing
    #else
    return UserDefaults.standard.bool(forKey: String.FeatureFlag.reEngagementTestMode)
    #endif
  }

  private func calculateTriggerDate() -> Date? {
    let calendar = Calendar.current
    let now = Date.now

    let triggerDate: Date?

    if isTestModeEnabled {
      // Test mode: 1 minute from now
      triggerDate = calendar.date(byAdding: .minute, value: 1, to: now)
      print("[Re-Engagement] Test mode - scheduling for 1 minute from now")
    } else {
      // Normal mode: 1 day from now at 11am
      guard let targetDate = calendar.date(byAdding: .day, value: 1, to: now) else {
        return nil
      }

      // Set to 11am on the target date
      var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
      components.hour = 11
      components.minute = 0

      triggerDate = calendar.date(from: components)
    }

    guard let finalTriggerDate = triggerDate else {
      return nil
    }

    // Don't schedule notifications in the past
    guard finalTriggerDate > now else {
      print("[Re-Engagement] Trigger date is in the past, skipping")
      return nil
    }

    return finalTriggerDate
  }

  private func createNotificationContent() -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = "Hey, it's Bud 👋"
    content.subtitle = "Ready to unlock your personalized health insights? We're almost there!"
    content.sound = .default
    content.categoryIdentifier = .CategoryID.reEngagementOnboarding

    return content
  }

  private func requestProvisionalAuthIfNeeded() async {
    let settings = await notificationCenter.notificationSettings()

    print("[Re-Engagement] Current auth status: \(settings.authorizationStatus.rawValue)")

    // Only request if not already determined
    guard settings.authorizationStatus == .notDetermined else {
      print("[Re-Engagement] Authorization already determined, skipping request")
      return
    }

    do {
      try await notificationCenter.requestAuthorization(options: [.provisional, .badge, .sound])
      print("[Re-Engagement] Requested provisional authorization")
    } catch {
      print("[Re-Engagement] Failed to request provisional authorization: \(error)")
    }
  }

  // MARK: - Debug Logging

  /// Logs all pending (scheduled but not yet delivered) notifications
  func logPendingNotifications() async {
    let requests = await notificationCenter.pendingNotificationRequests()
    print("[Re-Engagement] === PENDING NOTIFICATIONS (\(requests.count)) ===")
    if requests.isEmpty {
      print("[Re-Engagement] No pending notifications")
    } else {
      for request in requests {
        print("[Re-Engagement] ID: \(request.identifier)")
        print("[Re-Engagement] Title: \(request.content.title)")
        print("[Re-Engagement] Subtitle: \(request.content.subtitle)")
        if let trigger = request.trigger as? UNCalendarNotificationTrigger {
          if let nextDate = trigger.nextTriggerDate() {
            let secondsUntil = Int(nextDate.timeIntervalSinceNow)
            let minutesUntil = secondsUntil / 60
            print("[Re-Engagement] Fires in: \(secondsUntil)s (\(minutesUntil)m)")
            print("[Re-Engagement] Trigger date: \(nextDate)")
          }
        }
      }
    }
    print("[Re-Engagement] ===========================")
  }
}
