//
//  MonitorResult.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation

/// The result of a monitor state calculation including findings for display.
public struct MonitorResult: Sendable, Equatable, Identifiable, Codable {

  /// Unique identifier combining monitor type and date
  public var id: String {
    "\(monitorType.rawValue)-\(calculatedAt.timeIntervalSince1970)"
  }

  /// Which monitor this result is for
  public let monitorType: MonitorType

  /// The calculated state
  public let state: MonitorStateValue

  /// Confidence level (0.0-1.0) based on data availability
  public let confidence: Double

  /// Number of consecutive days in this state (for persistence rule)
  public let consecutiveDays: Int

  /// Signals that contributed to this state
  public let signals: [Signal]

  /// Human-readable findings to display to user
  public let findings: [Finding]

  /// Date this result was calculated
  public let calculatedAt: Date

  /// For stress monitor only: whether this is training stress or burnout
  public let stressSubtype: StressSubtype?

  /// Whether this state has met the persistence threshold (2+ days for Watch/Off)
  public var isPersistent: Bool {
    consecutiveDays >= 2
  }

  public init(
    monitorType: MonitorType,
    state: MonitorStateValue,
    confidence: Double,
    consecutiveDays: Int,
    signals: [Signal],
    findings: [Finding],
    calculatedAt: Date = Date(),
    stressSubtype: StressSubtype? = nil
  ) {
    self.monitorType = monitorType
    self.state = state
    self.confidence = confidence
    self.consecutiveDays = consecutiveDays
    self.signals = signals
    self.findings = findings
    self.calculatedAt = calculatedAt
    self.stressSubtype = stressSubtype
  }
}

/// Subtype classification for the Stress monitor
public enum StressSubtype: String, Sendable, Codable, Equatable {
  /// High training load causing physiological stress (overtraining)
  case trainingStress = "Training Stress"
  /// Normal/low training load with physiological stress signals (life stress, burnout)
  case burnout = "Burnout"

  public var displayName: String { rawValue }
}

// MARK: - Unavailable Result Factory

extension MonitorResult {

  /// Creates an unavailable result with an explanation finding
  static func unavailable(
    monitorType: MonitorType,
    reason: String,
    requiredMetrics: [MonitorMetricType]
  ) -> MonitorResult {
    MonitorResult(
      monitorType: monitorType,
      state: .unavailable,
      confidence: 0,
      consecutiveDays: 0,
      signals: [],
      findings: [
        Finding(
          title: "Insufficient Data",
          explanation: reason,
          confidence: .low,
          relatedMetrics: requiredMetrics
        )
      ]
    )
  }
}
