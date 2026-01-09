//
//  Finding.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation

/// A finding represents a user-facing explanation of what was detected by a monitor.
/// Findings use non-medical, confidence-aware language.
public struct Finding: Sendable, Equatable, Identifiable {

  public let id: String

  /// Short title for the finding (e.g., "Your resting heart rate is higher than usual")
  public let title: String

  /// Longer explanation following the template: what we noticed, how long, what it might mean, what you might do
  public let explanation: String

  /// Confidence level based on data quality and corroboration
  public let confidence: FindingConfidence

  /// The metrics that contributed to this finding
  public let relatedMetrics: [MonitorMetricType]

  public init(
    title: String,
    explanation: String,
    confidence: FindingConfidence,
    relatedMetrics: [MonitorMetricType]
  ) {
    self.id = UUID().uuidString
    self.title = title
    self.explanation = explanation
    self.confidence = confidence
    self.relatedMetrics = relatedMetrics
  }
}

/// Confidence level for a finding
public enum FindingConfidence: String, Sendable, Codable {
  /// Multiple corroborating signals
  case high
  /// Single strong signal or partially corroborated
  case medium
  /// Single weak signal or missing optional data
  case low
}
