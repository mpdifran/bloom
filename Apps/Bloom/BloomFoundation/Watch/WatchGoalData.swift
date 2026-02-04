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

/// Lightweight goal data for watch display.
/// Note: Current values are fetched from HealthKit on the watch, not synced from iOS.
public struct WatchGoal: Codable, Sendable, Identifiable, Equatable {
  public let id: String
  public let metricName: String
  public let metricSystemImage: String
  public let metricColorHex: String?
  public let targetValue: Double
  public let targetUnit: String
  public let timePeriod: String

  public init(
    id: String,
    metricName: String,
    metricSystemImage: String,
    metricColorHex: String?,
    targetValue: Double,
    targetUnit: String,
    timePeriod: String
  ) {
    self.id = id
    self.metricName = metricName
    self.metricSystemImage = metricSystemImage
    self.metricColorHex = metricColorHex
    self.targetValue = targetValue
    self.targetUnit = targetUnit
    self.timePeriod = timePeriod
  }

  // Custom Decodable to handle backward compatibility with cached data
  // that doesn't have the timePeriod field
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    metricName = try container.decode(String.self, forKey: .metricName)
    metricSystemImage = try container.decode(String.self, forKey: .metricSystemImage)
    metricColorHex = try container.decodeIfPresent(String.self, forKey: .metricColorHex)
    targetValue = try container.decode(Double.self, forKey: .targetValue)
    targetUnit = try container.decode(String.self, forKey: .targetUnit)
    timePeriod = try container.decodeIfPresent(String.self, forKey: .timePeriod) ?? "daily"
  }

  private enum CodingKeys: String, CodingKey {
    case id, metricName, metricSystemImage, metricColorHex
    case targetValue, targetUnit, timePeriod
  }
}
