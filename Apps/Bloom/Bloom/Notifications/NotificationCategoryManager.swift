//
//  NotificationCategoryManager.swift
//  Bloom
//
//  Created by Assistant on 2025-08-03.
//

import Foundation
import UserNotifications
import BloomFoundation

final class NotificationCategoryManager {
  static let shared = NotificationCategoryManager()
  
  private init() {}
  
  /// Registers all notification categories with their actions
  func registerNotificationCategories() async {
    let categories = createNotificationCategories()
    UNUserNotificationCenter.current().setNotificationCategories(categories)
  }
  
  private func createNotificationCategories() -> Set<UNNotificationCategory> {
    var categories: Set<UNNotificationCategory> = []

    // Reminders category with Complete action
    let completeAction = UNNotificationAction(
      identifier: .ActionID.completeReminder,
      title: "Complete",
      options: [.authenticationRequired],
      icon: UNNotificationActionIcon(systemImageName: "checkmark")
    )

    let remindersCategory = UNNotificationCategory(
      identifier: .CategoryID.reminders,
      actions: [completeAction],
      intentIdentifiers: [],
      options: []
    )

    categories.insert(remindersCategory)

    // Trial reminder category with Review Subscription and Leave Feedback actions
    let reviewSubscriptionAction = UNNotificationAction(
      identifier: .ActionID.reviewSubscription,
      title: "Review Subscription",
      options: [.foreground],
      icon: UNNotificationActionIcon(systemImageName: "creditcard")
    )

    let leaveFeedbackAction = UNNotificationAction(
      identifier: .ActionID.leaveFeedback,
      title: "Leave Feedback",
      options: [.foreground],
      icon: UNNotificationActionIcon(systemImageName: "envelope")
    )

    let trialReminderCategory = UNNotificationCategory(
      identifier: .CategoryID.trialReminder,
      actions: [reviewSubscriptionAction, leaveFeedbackAction],
      intentIdentifiers: [],
      options: []
    )

    categories.insert(trialReminderCategory)

    // Period prediction category with Log Period action
    let logPeriodAction = UNNotificationAction(
      identifier: .ActionID.logPeriod,
      title: "Log Period",
      options: [.foreground],
      icon: UNNotificationActionIcon(systemImageName: "calendar.badge.plus")
    )

    let periodPredictionCategory = UNNotificationCategory(
      identifier: .CategoryID.periodPrediction,
      actions: [logPeriodAction],
      intentIdentifiers: [],
      options: []
    )

    categories.insert(periodPredictionCategory)

    // Monitor alert category with View and Snooze actions
    let viewMonitorAction = UNNotificationAction(
      identifier: .ActionID.viewMonitor,
      title: "View Details",
      options: [.foreground],
      icon: UNNotificationActionIcon(systemImageName: "heart.text.square")
    )

    let snoozeMonitorAction = UNNotificationAction(
      identifier: .ActionID.snoozeMonitor,
      title: "Snooze 1 Day",
      options: [],
      icon: UNNotificationActionIcon(systemImageName: "moon.zzz")
    )

    let monitorAlertCategory = UNNotificationCategory(
      identifier: .CategoryID.monitorAlert,
      actions: [viewMonitorAction, snoozeMonitorAction],
      intentIdentifiers: [],
      options: []
    )

    categories.insert(monitorAlertCategory)

    // Workout completion category with View Analysis action
    let viewWorkoutAnalysisAction = UNNotificationAction(
      identifier: .ActionID.viewWorkoutAnalysis,
      title: "View Analysis",
      options: [.foreground],
      icon: UNNotificationActionIcon(systemImageName: "figure.run")
    )

    let workoutCompletionCategory = UNNotificationCategory(
      identifier: .CategoryID.workoutCompletion,
      actions: [viewWorkoutAnalysisAction],
      intentIdentifiers: [],
      options: []
    )

    categories.insert(workoutCompletionCategory)

    return categories
  }
}
