//
//  SuggestedGoal.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation

public extension SuggestedGoal {
  enum Metric: String, Codable, Equatable, Sendable, CaseIterable {
    case steps
    case waterIntake
    case exerciseMinutes
    case fiberIntake
    case bikeDistance
    case runningDistance
    case targetHeartRateZone1
    case targetHeartRateZone2
    case targetHeartRateZone3
    case targetHeartRateZone4
    case targetHeartRateZone5
  }
}

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
