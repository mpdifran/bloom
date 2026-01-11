//
//  MonitorSummaryRequest.swift
//  BloomModel
//
//  Created by Claude on 2026-01-10.
//

import Foundation

/// Request body for generating an AI-powered monitor summary.
/// Sent when a monitor transitions to Attention or Alert state.
public struct MonitorSummaryRequest: Codable, Hashable, Sendable {

  /// JSON-encoded monitor detection results (MonitorResult array)
  public let monitorContext: String

  /// JSON-encoded health baseline data (metric averages, z-scores)
  public let healthContext: String

  /// User's timezone identifier (e.g., "America/Toronto")
  public let timezone: String

  public init(
    monitorContext: String,
    healthContext: String,
    timezone: String
  ) {
    self.monitorContext = monitorContext
    self.healthContext = healthContext
    self.timezone = timezone
  }
}
