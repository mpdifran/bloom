//
//  MonitorInsightRequest.swift
//  BloomModel
//
//  Created by Claude on 2026-01-19.
//

import Foundation

/// Request body for generating an AI-powered monitor insight.
/// Sent when a user views a monitor's detail view.
public struct MonitorInsightRequest: Codable, Hashable, Sendable {

  /// The specific monitor type requesting insight ("recovery", "stress", "sleep")
  public let monitorType: String

  /// JSON-encoded current MonitorResult (state, signals, findings)
  public let monitorContext: String

  /// JSON-encoded relevant health data for this monitor
  public let healthContext: String

  /// User's timezone identifier (e.g., "America/Toronto")
  public let timezone: String

  public init(
    monitorType: String,
    monitorContext: String,
    healthContext: String,
    timezone: String
  ) {
    self.monitorType = monitorType
    self.monitorContext = monitorContext
    self.healthContext = healthContext
    self.timezone = timezone
  }
}
