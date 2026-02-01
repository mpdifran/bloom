//
//  WatchGoalData.swift
//  BloomFoundation
//
//  Created by Claude on 2026-02-01.
//

import Foundation

/// Lightweight goal data for watch synchronization.
/// Contains only the data needed by the watchOS widget.
public struct WatchGoalData: Codable, Sendable {
  public let goals: [WatchGoal]
  public let lastUpdated: Date

  public init(
    goals: [WatchGoal],
    lastUpdated: Date = Date()
  ) {
    self.goals = goals
    self.lastUpdated = lastUpdated
  }
}

/// Lightweight goal data for watch display
public struct WatchGoal: Codable, Sendable, Identifiable, Equatable {
  public let id: String
  public let metricName: String
  public let metricSystemImage: String
  public let metricColorHex: String?
  public let currentValue: Double
  public let targetValue: Double
  public let targetUnit: String

  public init(
    id: String,
    metricName: String,
    metricSystemImage: String,
    metricColorHex: String?,
    currentValue: Double,
    targetValue: Double,
    targetUnit: String
  ) {
    self.id = id
    self.metricName = metricName
    self.metricSystemImage = metricSystemImage
    self.metricColorHex = metricColorHex
    self.currentValue = currentValue
    self.targetValue = targetValue
    self.targetUnit = targetUnit
  }

  /// Progress toward the goal (0.0 to 1.0+)
  public var progress: Double {
    guard targetValue > 0 else { return 0 }
    return currentValue / targetValue
  }
}
