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
  public let unit: Unit
  public let notes: String

  public init(
    metric: Metric,
    value: Double,
    unit: Unit,
    notes: String
  ) {
    self.metric = metric
    self.value = value
    self.unit = unit
    self.notes = notes
  }
}

public extension SuggestedGoal {
  enum Metric: String, Codable, Equatable, Sendable, CaseIterable {
    case waterIntake
    case fiberIntake
    case meditationMinutes
    case exerciseMinutes
    case stepCount
    case walkingRunningDistance
    case runDistance
    case runDuration
    case bikeDistance
    case bikeDuration
    case mobilityAndFlexibilityDuration
    case strengthTrainingDuration
    case cardioDuration
    case highIntensityIntervalTrainingDuration
    case targetHeartRateZone1Minutes
    case targetHeartRateZone2Minutes
    case targetHeartRateZone3Minutes
    case targetHeartRateZone4Minutes
    case targetHeartRateZone5Minutes
  }
}

public extension SuggestedGoal {
  enum Unit: String, Codable, Equatable, Sendable, CaseIterable {
    case g
    case mg
    case mcg
    case steps
    case mL
    case min
    case hr
    case oz
    case km
    case mi
  }
}
