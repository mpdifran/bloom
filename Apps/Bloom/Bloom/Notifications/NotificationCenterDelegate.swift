//
//  NotificationCenterDelegate.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-12.
//

import Foundation
@preconcurrency import UserNotifications
import SwiftData
import DataContainer
import BloomFoundation
import UIKit
import RevenueCat
import TelemetryDeck

extension Notification.Name {
  static let showLogPeriodSheet = Notification.Name("showLogPeriodSheet")
  static let navigateToMonitor = Notification.Name("navigateToMonitor")
  static let navigateToWorkout = Notification.Name("navigateToWorkout")
}

@MainActor
final class NotificationCenterDelegate: NSObject {

  private let onNotificationResponse: @Sendable (UNNotificationResponse) -> Void

  init(onNotificationResponse: @escaping @Sendable (UNNotificationResponse) -> Void) {
    self.onNotificationResponse = onNotificationResponse

    super.init()

    UNUserNotificationCenter.current().delegate = self
  }
}

extension NotificationCenterDelegate: UNUserNotificationCenterDelegate {

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    // Handle notification actions
    await handleNotificationAction(response)
    await MainActor.run {
      onNotificationResponse(response)
    }
  }

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    switch notification.request.content.categoryIdentifier {
    case .CategoryID.chatMessage:
      return [.banner, .sound, .list]
    case .CategoryID.reminders:
      // Check if this reminder has been completed
      if await isReminderCompleted(notification: notification) {
        // Don't show notification for completed reminders
        return []
      }
      return [.banner, .sound, .list]
    case .CategoryID.trialReminder:
      return [.banner, .sound, .list]
    case .CategoryID.periodPrediction:
      return [.banner, .sound, .list]
    default:
      return [.banner, .sound, .list]
    }
  }

  // MARK: - Private Methods

  private func handleNotificationAction(_ response: UNNotificationResponse) async {
    let categoryID = response.notification.request.content.categoryIdentifier

    switch response.actionIdentifier {
    case .ActionID.completeReminder where categoryID == .CategoryID.reminders:
      await handleCompleteReminderAction(response.notification)
    case .ActionID.reviewSubscription where categoryID == .CategoryID.trialReminder:
      await handleReviewSubscriptionAction()
    case .ActionID.leaveFeedback where categoryID == .CategoryID.trialReminder:
      await handleLeaveFeedbackAction()
    case .ActionID.logPeriod where categoryID == .CategoryID.periodPrediction:
      await handleLogPeriodAction()
    case .ActionID.viewMonitor where categoryID == .CategoryID.monitorAlert:
      await handleViewMonitorAction()
    case .ActionID.snoozeMonitor where categoryID == .CategoryID.monitorAlert:
      await handleSnoozeMonitorAction(response.notification)
    case UNNotificationDefaultActionIdentifier where categoryID == .CategoryID.monitorAlert:
      // User tapped the notification itself (not an action button)
      await handleViewMonitorAction()
    case .ActionID.viewWorkoutAnalysis where categoryID == .CategoryID.workoutCompletion:
      await handleViewWorkoutAction(response.notification)
    case UNNotificationDefaultActionIdentifier where categoryID == .CategoryID.workoutCompletion:
      // User tapped the notification itself (not an action button)
      await handleViewWorkoutAction(response.notification)
    default:
      break
    }
  }

  private func handleCompleteReminderAction(_ notification: UNNotification) async {
    guard let reminderID = notification.request.content.userInfo["reminderID"] as? String,
          let occurrenceID = notification.request.content.userInfo["occurrenceID"] as? String else {
      print("NotificationCenterDelegate: Missing reminderID or occurrenceID in notification userInfo")
      return
    }

    do {
      try await RemindersManager.shared.markReminderCompleted(withID: reminderID, occurrenceID: occurrenceID)
      print("NotificationCenterDelegate: Successfully completed reminder \(reminderID)")
    } catch {
      print("NotificationCenterDelegate: Failed to complete reminder \(reminderID): \(error)")
    }
  }

  private func handleReviewSubscriptionAction() async {
    do {
      try await Purchases.shared.showManageSubscriptions()
      TelemetryDeck.signal("View Manage Subscriptions")
    } catch {
      print("NotificationCenterDelegate: Failed to show manage subscriptions: \(error)")
    }
  }

  private func handleLeaveFeedbackAction() async {
    let mailURL = URL.emailBloom(subject: "Bloom Plus Feedback")
    await MainActor.run {
      UIApplication.shared.open(mailURL)
    }
    TelemetryDeck.signal("Leave Feedback From Trial Reminder")
  }

  private func handleLogPeriodAction() async {
    // Post notification to trigger log period sheet
    await MainActor.run {
      NotificationCenter.default.post(name: .showLogPeriodSheet, object: nil)
    }
    TelemetryDeck.signal("Log Period From Notification")
  }

  private func handleViewMonitorAction() async {
    // Post notification to navigate to Monitor tab
    await MainActor.run {
      NotificationCenter.default.post(name: .navigateToMonitor, object: nil)
    }
    TelemetryDeck.signal("View Monitor From Notification")
  }

  private func handleSnoozeMonitorAction(_ notification: UNNotification) async {
    guard let monitorTypeRaw = notification.request.content.userInfo["monitorType"] as? String,
          let monitorType = MonitorType(rawValue: monitorTypeRaw) else {
      print("NotificationCenterDelegate: Missing or invalid monitorType in notification userInfo")
      return
    }

    // Snooze for 1 day
    MonitorNotificationPreferences.shared.snooze(monitorType, for: 86400)
    TelemetryDeck.signal("Snooze Monitor From Notification", parameters: ["monitorType": monitorTypeRaw])
  }

  private func handleViewWorkoutAction(_ notification: UNNotification) async {
    let workoutUUID = notification.request.content.userInfo["workoutUUID"] as? String

    // Post notification to navigate to Workouts tab and show workout details
    await MainActor.run {
      NotificationCenter.default.post(
        name: .navigateToWorkout,
        object: nil,
        userInfo: workoutUUID.map { ["workoutUUID": $0] }
      )
    }
    TelemetryDeck.signal("View Workout From Notification")
  }

  private func isReminderCompleted(notification: UNNotification) async -> Bool {
    // Extract reminder ID and occurrence ID from userInfo
    guard let reminderID = notification.request.content.userInfo["reminderID"] as? String,
          let occurrenceID = notification.request.content.userInfo["occurrenceID"] as? String else {
      // If we can't get IDs, show the notification to be safe
      return false
    }

    do {
      // Get the shared model container
      let container = ContainerHolder.shared.container
      let context = ModelContext(container)

      // Get date range for today
      let calendar = Calendar.current
      let startOfToday = calendar.startOfDay(for: Date())
      let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()

      // Simple predicate to avoid slow type-checking from optional chaining
      let descriptor = FetchDescriptor<ReminderCompletionRecord>(
        predicate: #Predicate<ReminderCompletionRecord> { completion in
          completion.completedDate >= startOfToday &&
          completion.completedDate <= endOfToday
        }
      )

      // Fetch today's completions, then filter in-memory for the specific reminder/occurrence
      let todayCompletions = try context.fetch(descriptor)
      let matchingCompletion = todayCompletions.first { completion in
        completion.reminder?.id == reminderID && completion.occurrence?.id == occurrenceID
      }
      return matchingCompletion != nil

    } catch {
      // If there's an error accessing the database, show the notification to be safe
      print("NotificationCenterDelegate: Error checking reminder completion: \(error)")
      return false
    }
  }
}
