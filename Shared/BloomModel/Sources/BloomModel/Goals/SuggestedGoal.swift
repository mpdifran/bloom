//
//  SuggestedGoal.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation

public struct SuggestedGoal: Codable, Equatable, Sendable {
  public let metric: Metric
  public let timePeriod: TimePeriod
  public let value: Double
  public let unit: Unit
  public let notes: String

  public init(
    metric: Metric,
    timePeriod: TimePeriod,
    value: Double,
    unit: Unit,
    notes: String
  ) {
    self.metric = metric
    self.timePeriod = timePeriod
    self.value = value
    self.unit = unit
    self.notes = notes
  }
}

public extension SuggestedGoal {
  enum Metric: String, Codable, Equatable, Sendable, CaseIterable {
    case calories
    case proteinIntake
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
  enum TimePeriod: String, Codable, Equatable, Sendable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
  }
}

public extension SuggestedGoal.Metric {
  static var validUnitDescription: String {
    var output = ""

    for metric in allCases {
      output.append("For \(metric.rawValue), use \(metric.validUnits.map({ $0.rawValue }))\n")
    }

    return output
  }

  var validUnits: [SuggestedGoal.Unit] {
    switch self {
    case .calories:
      return [.cal]
    case .proteinIntake:
      return [.g]
    case .waterIntake:
      return [.mL, .oz]
    case .fiberIntake:
      return [.g]
    case .meditationMinutes, .exerciseMinutes, .runDuration, .bikeDuration, .mobilityAndFlexibilityDuration,
         .strengthTrainingDuration, .cardioDuration, .highIntensityIntervalTrainingDuration,
         .targetHeartRateZone1Minutes, .targetHeartRateZone2Minutes,
         .targetHeartRateZone3Minutes, .targetHeartRateZone4Minutes,
         .targetHeartRateZone5Minutes:
      return [.min, .hr]
    case .stepCount:
      return [.steps]
    case .walkingRunningDistance, .runDistance, .bikeDistance:
      return [.km, .mi]
    }
  }

  var supportedTimePeriods: [SuggestedGoal.TimePeriod] {
    switch self {
    case .calories, .proteinIntake, .waterIntake, .fiberIntake:
      return [.daily]
    default:
      return [.daily, .weekly, .monthly, .yearly]
    }
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
    case cal
  }
}
