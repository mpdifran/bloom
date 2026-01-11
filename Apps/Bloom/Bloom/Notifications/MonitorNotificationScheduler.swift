//
//  MonitorNotificationScheduler.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import Foundation
@preconcurrency import UserNotifications
import BloomFoundation

/// Actor responsible for scheduling monitor state change notifications.
/// Sends notifications when a monitor transitions to Attention or Alert state.
public actor MonitorNotificationScheduler {

  public static let shared = MonitorNotificationScheduler()

  private let notificationCenter = UNUserNotificationCenter.current()

  private init() {}

  // MARK: - Public API

  /// Checks if a notification should be sent for a state change and schedules it if needed.
  /// - Parameters:
  ///   - result: The current monitor result
  ///   - previousState: The previous state for this monitor (nil if first calculation)
  public func scheduleNotificationIfNeeded(
    result: MonitorResult,
    previousState: MonitorStateValue?
  ) async {
    // Only notify on concerning states (Attention or Alert)
    guard result.state.isConcerning else { return }

    // Only notify on state *changes* - don't re-notify if state is the same
    if let previous = previousState, previous == result.state {
      return
    }

    // Check user preferences
    guard MonitorNotificationPreferences.shared.shouldNotify(for: result.monitorType) else {
      return
    }

    // Schedule the notification
    await scheduleNotification(for: result)
  }

  /// Sends a test notification immediately (for developer settings).
  public func sendTestNotification(for monitorType: MonitorType, state: MonitorStateValue) async {
    let content = createNotificationContent(monitorType: monitorType, state: state)

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil // nil trigger means send immediately
    )

    do {
      try await notificationCenter.add(request)
      print("MonitorNotificationScheduler: Sent test notification for \(monitorType.displayName)")
    } catch {
      print("MonitorNotificationScheduler: Failed to send test notification: \(error)")
    }
  }

  /// Cancels all pending monitor notifications.
  public func cancelAllMonitorNotifications() async {
    let identifiers = [
      String.NotificationID.monitorRecoveryAttention,
      String.NotificationID.monitorRecoveryAlert,
      String.NotificationID.monitorStressAttention,
      String.NotificationID.monitorStressAlert,
      String.NotificationID.monitorSleepAttention,
      String.NotificationID.monitorSleepAlert
    ]

    notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
  }

  // MARK: - Private Methods

  private func scheduleNotification(for result: MonitorResult) async {
    // Try to get cached AI summary for enhanced notification body
    let cachedSummary = await MonitorSummaryCache.shared.getCachedSummary()

    let content = createNotificationContent(
      monitorType: result.monitorType,
      state: result.state,
      aiSummaryBody: cachedSummary?.notificationBody
    )
    let identifier = notificationIdentifier(for: result.monitorType, state: result.state)

    // Remove any existing notification for this monitor/state combination
    notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])

    let request = UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: nil // Send immediately
    )

    do {
      try await notificationCenter.add(request)
      print("MonitorNotificationScheduler: Scheduled notification for \(result.monitorType.displayName) - \(result.state.displayName)")
    } catch {
      print("MonitorNotificationScheduler: Failed to schedule notification: \(error)")
    }
  }

  private func createNotificationContent(
    monitorType: MonitorType,
    state: MonitorStateValue,
    aiSummaryBody: String? = nil
  ) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.sound = .default
    content.categoryIdentifier = .CategoryID.monitorAlert

    // Store monitor type in userInfo for action handling
    content.userInfo = ["monitorType": monitorType.rawValue]

    switch state {
    case .attention:
      content.title = "\(monitorType.displayName) Needs Attention"
      // Use AI-generated body if available, otherwise fallback
      content.body = aiSummaryBody ?? "Some of your health metrics are trending outside your normal range."
    case .alert:
      content.title = "\(monitorType.displayName) Alert"
      // Use AI-generated body if available, otherwise fallback
      content.body = aiSummaryBody ?? "Your health metrics show significant changes that may need attention."
    default:
      // Should not happen - we only notify for concerning states
      content.title = monitorType.displayName
      content.body = "Tap to view details."
    }

    return content
  }

  private func notificationIdentifier(for monitorType: MonitorType, state: MonitorStateValue) -> String {
    switch (monitorType, state) {
    case (.recovery, .attention):
      return .NotificationID.monitorRecoveryAttention
    case (.recovery, .alert):
      return .NotificationID.monitorRecoveryAlert
    case (.stress, .attention):
      return .NotificationID.monitorStressAttention
    case (.stress, .alert):
      return .NotificationID.monitorStressAlert
    case (.sleep, .attention):
      return .NotificationID.monitorSleepAttention
    case (.sleep, .alert):
      return .NotificationID.monitorSleepAlert
    default:
      return "monitor-\(monitorType.rawValue)-\(state.rawValue)"
    }
  }
}
