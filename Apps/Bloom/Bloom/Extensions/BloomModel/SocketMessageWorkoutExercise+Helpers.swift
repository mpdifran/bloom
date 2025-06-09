//
//  SocketMessageWorkoutExercise+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-29.
//

import Foundation
import BloomModel
import DataContainer
import HealthKit

extension SocketMessage.WorkoutExercise {

  var distanceQuantity: HKQuantity? {
    guard let distance, let distanceUnit else { return nil }

    return HKQuantity(unit: distanceUnit.hkUnit, doubleValue: distance)
  }

  @MainActor
  var parameterDescription: String {
    [
      durationDescription,
      distanceDescription,
      repsDescription
    ]
      .compactMap { $0 }
      .joined(separator: " • ")
  }

  var durationDescription: String {
    DateFormatter.timeIntervalHourMinuteShort.string(from: DateComponents(second: Int(duration))) ?? ""
  }

  @MainActor
  var distanceDescription: String? {
    guard let distanceQuantity, let distanceUnit else { return nil }

    return distanceQuantity.displayString(for: distanceUnit.hkUnit)
  }

  var repsDescription: String? {
    guard let numberOfReps else { return nil }

    return "\(numberOfReps) Reps"
  }

  @MainActor
  var measurementDescription: String {
    if let repsDescription {
      return repsDescription
    } else if let distanceQuantity, let distanceUnit {
      return distanceQuantity.displayString(for: distanceUnit.hkUnit)
    } else {
      return DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: DateComponents(second: Int(duration))) ?? ""
    }
  }
}

extension SocketMessage.WorkoutPlan.Equipment {

  var hkEquipment: WorkoutPlan.Equipment {
    switch self {
    case .dumbbells: .dumbbells
    case .barbell: .barbell
    case .kettlebell: .kettlebell
    case .batBell: .batBell
    case .chinUpBar: .chinUpBar
    case .treadmill: .treadmill
    case .stationaryBike: .stationaryBike
    case .bike: .bike
    case .elliptical: .elliptical
    case .rowingMachine: .rowingMachine
    case .skiMachine: .skiMachine
    case .yogaMat: .yogaMat
    case .resistanceBand: .resistanceBand
    case .weightedVest: .weightedVest
    }
  }
}

extension SocketMessage.WorkoutExercise.DistanceUnit {

  var swiftDataUnit: WorkoutExercise.DistanceUnit {
    switch self {
    case .meter: .meter
    case .kilometer: .kilometer
    case .mile: .mile
    case .yard: .yard
    case .foot: .foot
    }
  }
}
