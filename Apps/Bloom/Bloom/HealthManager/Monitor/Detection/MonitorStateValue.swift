//
//  MonitorStateValue.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation

/// The computed state for a monitor
public enum MonitorStateValue: String, Sendable, Codable, CaseIterable {
  /// All metrics within normal range
  case good
  /// Some concerning signals, user should be aware
  case watch
  /// Significant deviation, user should take action
  case off
  /// Insufficient data to calculate state
  case unavailable

  public var displayName: String {
    switch self {
    case .good: return "Good"
    case .watch: return "Watch"
    case .off: return "Off"
    case .unavailable: return "Unavailable"
    }
  }

  /// Priority for sorting (higher = more urgent)
  public var priority: Int {
    switch self {
    case .off: return 3
    case .watch: return 2
    case .good: return 1
    case .unavailable: return 0
    }
  }

  /// Whether this state represents a concerning condition
  public var isConcerning: Bool {
    switch self {
    case .watch, .off:
      return true
    case .good, .unavailable:
      return false
    }
  }
}
