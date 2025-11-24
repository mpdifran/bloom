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
  func scheduleNotificationIfNeeded(focus: PersonalizationFocus? = nil) async {
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
      await scheduleNotification(focus: focus)
    }
  }

  /// Cancels the re-engagement notification
  func cancelNotification() async {
    notificationCenter.removePendingNotificationRequests(withIdentifiers: [.NotificationID.reEngagement])
    notificationCenter.removeDeliveredNotifications(withIdentifiers: [.NotificationID.reEngagement])
    print("[Re-Engagement] Cancelled notification")
  }

  // MARK: - Private Methods

  private func scheduleNotification(focus: PersonalizationFocus?) async {
    // Calculate trigger date: 1 day from now (or minutes in test mode) at 11am
    guard let triggerDate = calculateTriggerDate() else {
      print("[Re-Engagement] Failed to calculate trigger date")
      return
    }

    let content = createNotificationContent(focus: focus)

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
      triggerDate = calendar.date(byAdding: .minute, value: 3, to: now)
      print("[Re-Engagement] Test mode - scheduling for 3 minutes from now")
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

  private func createNotificationContent(focus: PersonalizationFocus?) -> UNMutableNotificationContent {
    let message = switch focus {
    case .understandHealthData:
      "Finish setting up Bloom so I can start explaining what your health data really means in simple, friendly language."
    case .boostEnergyLevels:
      "Let’s finish your setup so I can start showing you what’s draining your energy, and what could help boost it."
    case .improveSleep:
      "Complete your setup and I’ll start showing you what’s affecting your sleep patterns and how to improve them."
    case .buildHealthyHabits:
      "Let’s wrap up your setup so I can help you build small, healthy habits that actually stick."
    case .reduceStress:
      "Finish your Bloom setup and I’ll start helping you spot what’s adding stress, and what brings you back to calm."
    case .improveBodyComposition:
      "Complete your setup so I can help you understand the factors influencing your body composition and how to make steady progress."
    case .custom, nil:
      "Want me to finish setting up your health insights? It only takes a moment."
    }

    let content = UNMutableNotificationContent()
    content.title = "Hey, it's Bud 👋"
    content.body = message
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
        print("[Re-Engagement] Body: \(request.content.body)")
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
