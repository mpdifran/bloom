//
//  MonitorInsightResponse.swift
//  BloomModel
//
//  Created by Claude on 2026-01-19.
//

import Foundation

/// Response containing an AI-generated monitor insight.
/// Generated when a user views a monitor's detail view.
public struct MonitorInsightResponse: Codable, Hashable, Sendable {

  /// A couple sentences providing personalized insight about the monitor state
  public let insight: String

  /// Optional single actionable suggestion (nil if not applicable)
  public let suggestion: String?

  public init(
    insight: String,
    suggestion: String? = nil
  ) {
    self.insight = insight
    self.suggestion = suggestion
  }
}
