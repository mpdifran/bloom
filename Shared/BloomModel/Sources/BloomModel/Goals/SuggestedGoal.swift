//
//  SuggestedGoal.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation

public struct SuggestedGoal: Codable, Equatable, Sendable {
  public let metric: Metric
  public let value: Double
  public let unit: String

  public init(
    metric: Metric,
    value: Double,
    unit: String
  ) {
    self.metric = metric
    self.value = value
    self.unit = unit
  }
}

public extension SuggestedGoal {
  enum Metric: String, Codable, Equatable, Sendable, CaseIterable {
    case steps
    case waterIntake
    case exerciseMinutes
    case fiberIntake
    case bikeDistance
    case runningDistance
    case targetHeartRateZone1Minutes
    case targetHeartRateZone2Minutes
    case targetHeartRateZone3Minutes
    case targetHeartRateZone4Minutes
    case targetHeartRateZone5Minutes
  }
}

public extension SuggestedGoal {
  enum Unit: String, Codable, Equatable, Sendable, CaseIterable {
    case mg
    case mcg
    case g
    case steps
    case mL
    case minute
    case hour
    case oz
    case km
    case mi
  }
}
