//
//  MonitorStateValue.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import SwiftUI

/// The computed state for a monitor
public enum MonitorStateValue: String, Sendable, Codable, CaseIterable {
  /// All metrics within normal range
  case good
  /// Some concerning signals, user should be aware
  case attention
  /// Significant deviation, user should take action
  case alert
  /// Insufficient data to calculate state
  case unavailable
  /// Positive nudge to encourage activity (for low activity users)
  case encourage

  public var displayName: String {
    switch self {
    case .good: return String(localized: "Typical")
    case .attention: return String(localized: "Attention")
    case .alert: return String(localized: "Alert")
    case .unavailable: return String(localized: "Unavailable")
    case .encourage: return String(localized: "Get Moving")
    }
  }

  /// Priority for sorting (higher = more urgent)
  public var priority: Int {
    switch self {
    case .alert: return 4
    case .attention: return 3
    case .good: return 2
    case .encourage: return 1
    case .unavailable: return 0
    }
  }

  /// Whether this state represents a concerning condition
  public var isConcerning: Bool {
    switch self {
    case .attention, .alert:
      return true
    case .good, .unavailable, .encourage:
      return false
    }
  }

  /// Numeric value for charting (higher = more severe)
  public var chartValue: Int {
    switch self {
    case .unavailable: return 0
    case .encourage: return 1
    case .good: return 2
    case .attention: return 3
    case .alert: return 4
    }
  }

  /// Color for this state
  public var color: Color {
    switch self {
    case .good: return .green
    case .attention: return .orange
    case .alert: return .red
    case .unavailable: return .gray
    case .encourage: return .blue
    }
  }
}
