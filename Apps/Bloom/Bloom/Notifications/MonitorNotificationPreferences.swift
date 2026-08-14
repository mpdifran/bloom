//
//  MonitorNotificationPreferences.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import Foundation
import SwiftUI

/// Manages user preferences for monitor notifications.
/// Persists enabled/disabled state and snooze status for each monitor type.
public final class MonitorNotificationPreferences: ObservableObject {

  public static let shared = MonitorNotificationPreferences()

  // MARK: - Enabled State

  @AppStorage("monitor.notifications.recovery.enabled")
  public var recoveryEnabled: Bool = true

  @AppStorage("monitor.notifications.stress.enabled")
  public var stressEnabled: Bool = true

  @AppStorage("monitor.notifications.sleep.enabled")
  public var sleepEnabled: Bool = true

  // MARK: - Badge State

  @AppStorage("monitor.badges.enabled")
  public var badgesEnabled: Bool = true

  // MARK: - Snooze State (stored as TimeInterval since reference date, 0 = not snoozed)

  @AppStorage("monitor.notifications.recovery.snoozedUntil")
  private var recoverySnoozedUntilInterval: Double = 0

  @AppStorage("monitor.notifications.stress.snoozedUntil")
  private var stressSnoozedUntilInterval: Double = 0

  @AppStorage("monitor.notifications.sleep.snoozedUntil")
  private var sleepSnoozedUntilInterval: Double = 0

  private init() {}

  // MARK: - Public Methods

  /// Returns whether notifications are enabled for the specified monitor.
  public func isEnabled(for monitorType: MonitorType) -> Bool {
    switch monitorType {
    case .recovery:
      return recoveryEnabled
    case .stress:
      return stressEnabled
    case .sleep:
      return sleepEnabled
    }
  }

  /// Sets whether notifications are enabled for the specified monitor.
  public func setEnabled(_ enabled: Bool, for monitorType: MonitorType) {
    switch monitorType {
    case .recovery:
      recoveryEnabled = enabled
    case .stress:
      stressEnabled = enabled
    case .sleep:
      sleepEnabled = enabled
    }
  }

  /// Returns the snooze end date for the specified monitor, or nil if not snoozed.
  public func snoozedUntil(for monitorType: MonitorType) -> Date? {
    let interval: Double
    switch monitorType {
    case .recovery:
      interval = recoverySnoozedUntilInterval
    case .stress:
      interval = stressSnoozedUntilInterval
    case .sleep:
      interval = sleepSnoozedUntilInterval
    }

    guard interval > 0 else { return nil }
    return Date(timeIntervalSinceReferenceDate: interval)
  }

  /// Returns whether the specified monitor is currently snoozed.
  public func isSnoozed(for monitorType: MonitorType) -> Bool {
    guard let snoozedUntil = snoozedUntil(for: monitorType) else {
      return false
    }
    return snoozedUntil > Date()
  }

  /// Snoozes notifications for the specified monitor for the given duration.
  public func snooze(_ monitorType: MonitorType, for duration: TimeInterval) {
    let snoozedUntil = Date().addingTimeInterval(duration)
    let interval = snoozedUntil.timeIntervalSinceReferenceDate

    switch monitorType {
    case .recovery:
      recoverySnoozedUntilInterval = interval
    case .stress:
      stressSnoozedUntilInterval = interval
    case .sleep:
      sleepSnoozedUntilInterval = interval
    }
  }

  /// Clears the snooze for the specified monitor.
  public func clearSnooze(for monitorType: MonitorType) {
    switch monitorType {
    case .recovery:
      recoverySnoozedUntilInterval = 0
    case .stress:
      stressSnoozedUntilInterval = 0
    case .sleep:
      sleepSnoozedUntilInterval = 0
    }
  }

  /// Returns whether notifications should be sent for the specified monitor.
  /// Takes into account both enabled state and snooze status.
  public func shouldNotify(for monitorType: MonitorType) -> Bool {
    return isEnabled(for: monitorType) && !isSnoozed(for: monitorType)
  }
}

// MARK: - Snooze Duration Options

public extension MonitorNotificationPreferences {

  /// Common snooze durations
  enum SnoozeDuration: CaseIterable {
    case oneDay
    case oneWeek
    case oneMonth

    public var timeInterval: TimeInterval {
      switch self {
      case .oneDay:
        return 24 * 60 * 60
      case .oneWeek:
        return 7 * 24 * 60 * 60
      case .oneMonth:
        return 30 * 24 * 60 * 60
      }
    }

    public var displayName: String {
      switch self {
      case .oneDay:
        return String(localized: "1 Day", comment: "Display name for monitor notification preferences")
      case .oneWeek:
        return String(localized: "1 Week", comment: "Display name for monitor notification preferences")
      case .oneMonth:
        return String(localized: "1 Month", comment: "Display name for monitor notification preferences")
      }
    }
  }
}
