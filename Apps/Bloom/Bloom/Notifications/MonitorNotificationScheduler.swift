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

  // UserDefaults keys for persisting last notified state
  private enum UserDefaultsKey {
    static let lastNotifiedRecoveryState = "monitor.lastNotified.recovery"
    static let lastNotifiedStressState = "monitor.lastNotified.stress"
    static let lastNotifiedSleepState = "monitor.lastNotified.sleep"
  }

  private init() {}

  // MARK: - Public API

  /// Checks if a notification should be sent for a state change and schedules it if needed.
  /// - Parameters:
  ///   - result: The current monitor result
  ///   - previousState: The previous state for this monitor (unused, kept for API compatibility)
  public func scheduleNotificationIfNeeded(
    result: MonitorResult,
    previousState: MonitorStateValue?
  ) async {
    // Only notify on concerning states (Attention or Alert)
    guard result.state.isConcerning else { return }

    // Use persisted last notified state (survives app restarts)
    let lastNotified = getLastNotifiedState(for: result.monitorType)

    // Don't re-notify if we already notified for this exact state
    if let lastNotified, lastNotified == result.state {
      return
    }

    // Check user preferences (must access on main thread)
    let shouldNotify = await MainActor.run {
      MonitorNotificationPreferences.shared.shouldNotify(for: result.monitorType)
    }
    guard shouldNotify else { return }

    // Schedule the notification
    await scheduleNotification(for: result)

    // Persist that we notified for this state
    setLastNotifiedState(result.state, for: result.monitorType)
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
    let content = createNotificationContent(
      monitorType: result.monitorType,
      state: result.state
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
    state: MonitorStateValue
  ) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.sound = .default
    content.categoryIdentifier = .CategoryID.monitorAlert

    // Store monitor type in userInfo for action handling
    content.userInfo = ["monitorType": monitorType.rawValue]

    content.title = "\(monitorType.displayName) \(state == .alert ? "Alert" : "Needs Attention")"
    content.body = notificationBody(for: monitorType, state: state)

    return content
  }

  private func notificationBody(for monitorType: MonitorType, state: MonitorStateValue) -> String {
    switch (monitorType, state) {
    case (.recovery, .attention):
      return "Your recovery metrics are outside your normal range. Consider taking it easy today."
    case (.recovery, .alert):
      return "Your body may be working harder than usual. Prioritize rest and recovery."
    case (.stress, .attention):
      return "Your training load or stress indicators are elevated. Monitor how you're feeling."
    case (.stress, .alert):
      return "Signs of overtraining or burnout detected. Consider a rest day."
    case (.sleep, .attention):
      return "Your sleep patterns have been inconsistent. Try to prioritize rest tonight."
    case (.sleep, .alert):
      return "Your sleep quality has been significantly impacted. Focus on improving your sleep routine."
    default:
      return "Tap to view details."
    }
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

  // MARK: - State Persistence

  /// Gets the last state we sent a notification for (persisted to UserDefaults).
  private nonisolated func getLastNotifiedState(for monitorType: MonitorType) -> MonitorStateValue? {
    let key: String
    switch monitorType {
    case .recovery: key = UserDefaultsKey.lastNotifiedRecoveryState
    case .stress: key = UserDefaultsKey.lastNotifiedStressState
    case .sleep: key = UserDefaultsKey.lastNotifiedSleepState
    }

    guard let rawValue = UserDefaults.standard.string(forKey: key) else { return nil }
    return MonitorStateValue(rawValue: rawValue)
  }

  /// Persists the state we just sent a notification for.
  private nonisolated func setLastNotifiedState(_ state: MonitorStateValue, for monitorType: MonitorType) {
    let key: String
    switch monitorType {
    case .recovery: key = UserDefaultsKey.lastNotifiedRecoveryState
    case .stress: key = UserDefaultsKey.lastNotifiedStressState
    case .sleep: key = UserDefaultsKey.lastNotifiedSleepState
    }

    UserDefaults.standard.set(state.rawValue, forKey: key)
  }
}
