//
//  Signal.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import SwiftUI

/// Represents a single metric deviation that's notable enough to contribute to a monitor state.
public struct Signal: Sendable, Equatable, Identifiable {

  public let id: String

  /// The metric that triggered this signal
  public let metricType: MonitorMetricType

  /// The date this signal was detected
  public let date: Date

  /// The z-score deviation (signed value, positive = above baseline, negative = below)
  public let zScore: Double

  /// Whether this deviation is concerning (direction matters per metric)
  public let direction: SignalDirection

  /// Human-readable description of what was detected
  public let description: String

  /// Absolute magnitude of deviation for severity comparison
  public var magnitude: Double { abs(zScore) }

  /// Severity based on z-score magnitude
  public var severity: SignalSeverity {
    switch magnitude {
    case 0..<1.0:
      return .normal
    case 1.0..<2.0:
      return .elevated
    default:
      return .high
    }
  }

  public init(
    metricType: MonitorMetricType,
    date: Date,
    zScore: Double,
    direction: SignalDirection,
    description: String
  ) {
    self.id = "\(date.timeIntervalSince1970)_\(metricType.rawValue)"
    self.metricType = metricType
    self.date = date
    self.zScore = zScore
    self.direction = direction
    self.description = description
  }
}

/// The direction of a signal deviation
public enum SignalDirection: String, Sendable, Codable {
  /// Value is above baseline (bad for RHR, wrist temp, respiratory rate)
  case higher
  /// Value is below baseline (bad for HRV, sleep duration)
  case lower
  /// Unusual variability (for bedtime/wake consistency)
  case variable
}

/// Severity level of a signal based on z-score magnitude
public enum SignalSeverity: String, Sendable, Codable, Comparable {
  /// < 1.0 z-score - within normal variation
  case normal
  /// 1.0 - 2.0 z-score - notable deviation
  case elevated
  /// > 2.0 z-score - significant deviation
  case high

  public static func < (lhs: SignalSeverity, rhs: SignalSeverity) -> Bool {
    let order: [SignalSeverity] = [.normal, .elevated, .high]
    guard let lhsIndex = order.firstIndex(of: lhs),
          let rhsIndex = order.firstIndex(of: rhs) else {
      return false
    }
    return lhsIndex < rhsIndex
  }

  /// Color for this severity level
  public var color: Color {
    switch self {
    case .normal:
      return .green
    case .elevated:
      return .orange
    case .high:
      return .red
    }
  }
}
