//
//  MonitorSummaryResponse.swift
//  BloomModel
//
//  Created by Claude on 2026-01-10.
//

import Foundation

/// Response containing an AI-generated monitor summary.
/// Generated when a monitor transitions to Attention or Alert state.
public struct MonitorSummaryResponse: Codable, Hashable, Sendable {

  /// 1-2 sentence overview of what the data shows (for UI card display)
  public let summary: String

  /// Concise 1-sentence version optimized for push notification body
  public let notificationBody: String

  /// Actionable suggestions (2-4 items)
  public let recommendations: [String]

  /// Optional additional context explaining the patterns
  public let contextNote: String?

  public init(
    summary: String,
    notificationBody: String,
    recommendations: [String],
    contextNote: String? = nil
  ) {
    self.summary = summary
    self.notificationBody = notificationBody
    self.recommendations = recommendations
    self.contextNote = contextNote
  }
}
