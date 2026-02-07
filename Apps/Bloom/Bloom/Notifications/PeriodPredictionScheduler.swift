//
//  PeriodPredictionScheduler.swift
//  Bloom
//
//  Created by Assistant on 2025-10-10.
//

import Foundation
@preconcurrency import UserNotifications
import CoreHealth
import BloomFoundation

public enum PeriodPredictionNotificationType {
  case near // 4 days before
  case imminent // 1 day before
  case late // 4 days after
}

actor PeriodPredictionScheduler {
  static let shared = PeriodPredictionScheduler()

  private let notificationCenter = UNUserNotificationCenter.current()

  private init() {}

  /// Schedules all period prediction notifications based on the current menstrual summary
  func schedulePeriodPredictionNotifications() async {
    // Cancel existing notifications first
    await cancelPeriodPredictionNotifications()

    // Get the menstrual summary
    let menstrualSummary = await YouStatsCalculator.shared.menstrualSummary

    guard let predictedDate = menstrualSummary?.nextPredictedPeriodDate else {
      print("PeriodPredictionScheduler: No predicted period date available")
      return
    }

    // Check if user is female (only schedule for female users)
    let isFemale = await HealthManager.shared.sex() == .female
    guard isFemale else {
      print("PeriodPredictionScheduler: User is not female, skipping scheduling")
      return
    }

    let calendar = Calendar.current

    // Schedule notification 4 days before
    if let nearDate = calendar.date(byAdding: .day, value: -4, to: predictedDate) {
      await scheduleNotification(
        type: .near,
        date: nearDate,
        predictedDate: predictedDate
      )
    }

    // Schedule notification 1 day before
    if let imminentDate = calendar.date(byAdding: .day, value: -1, to: predictedDate) {
      await scheduleNotification(
        type: .imminent,
        date: imminentDate,
        predictedDate: predictedDate
      )
    }

    // Schedule notification 4 days after (late period)
    if let lateDate = calendar.date(byAdding: .day, value: 4, to: predictedDate) {
      await scheduleNotification(
        type: .late,
        date: lateDate,
        predictedDate: predictedDate
      )
    }

    print("PeriodPredictionScheduler: Scheduled notifications for predicted date: \(predictedDate)")
  }

  /// Cancels all period prediction notifications
  func cancelPeriodPredictionNotifications() async {
    let identifiers = [
      String.NotificationID.periodPredictionNear,
      String.NotificationID.periodPredictionImminent,
      String.NotificationID.periodPredictionLate
    ]

    notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)

    print("PeriodPredictionScheduler: Cancelled all period prediction notifications")
  }

  /// Sends a test notification immediately (for debug purposes)
  public func sendTestNotification(type: PeriodPredictionNotificationType) async {
    let content = createNotificationContent(type: type, predictedDate: Date())

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil // nil trigger means send immediately
    )

    do {
      try await notificationCenter.add(request)
      print("PeriodPredictionScheduler: Sent test notification for type: \(type)")
    } catch {
      print("PeriodPredictionScheduler: Failed to send test notification: \(error)")
    }
  }

  // MARK: - Private Methods

  private func scheduleNotification(
    type: PeriodPredictionNotificationType,
    date: Date,
    predictedDate: Date
  ) async {
    // Don't schedule notifications in the past
    guard date > Date() else {
      print("PeriodPredictionScheduler: Skipping notification in the past for type: \(type)")
      return
    }

    let content = createNotificationContent(type: type, predictedDate: predictedDate)

    let dateComponents = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute],
      from: date
    )

    let trigger = UNCalendarNotificationTrigger(
      dateMatching: dateComponents,
      repeats: false
    )

    let identifier = notificationIdentifier(for: type)

    let request = UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: trigger
    )

    do {
      try await notificationCenter.add(request)
      print("PeriodPredictionScheduler: Scheduled \(type) notification for \(date)")
    } catch {
      print("PeriodPredictionScheduler: Failed to schedule notification: \(error)")
    }
  }

  private func createNotificationContent(
    type: PeriodPredictionNotificationType,
    predictedDate: Date
  ) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.sound = .default
    content.categoryIdentifier = .CategoryID.periodPrediction

    switch type {
    case .near:
      content.title = "Period May Be Coming"
      content.subtitle = "Your period may start soon."

    case .imminent:
      content.title = "Period Likely Tomorrow"
      content.subtitle = "Your period is likely to start tomorrow."

    case .late:
      content.title = "Late Period"
      content.subtitle = "Did you forget to log your period, or is it late?"
    }

    return content
  }

  private func notificationIdentifier(for type: PeriodPredictionNotificationType) -> String {
    switch type {
    case .near:
      return .NotificationID.periodPredictionNear
    case .imminent:
      return .NotificationID.periodPredictionImminent
    case .late:
      return .NotificationID.periodPredictionLate
    }
  }
}
