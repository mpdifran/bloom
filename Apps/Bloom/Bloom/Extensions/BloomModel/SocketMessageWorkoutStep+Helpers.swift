//
//  SocketMessageWorkoutStep+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-29.
//

import Foundation
import BloomModel
import DataContainer
import HealthKit

extension SocketMessage.WorkoutStep {

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

  var durationDescription: String? {
    guard let duration else { return nil }

    return DateFormatter.timeIntervalHourMinuteShort.string(from: DateComponents(second: Int(duration))) ?? ""
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
}

extension SocketMessage.WorkoutTemplate.Equipment {

  var hkEquipment: WorkoutTemplate.Equipment {
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

extension SocketMessage.WorkoutStep.DistanceUnit {

  var swiftDataUnit: WorkoutStep.DistanceUnit {
    switch self {
    case .meter: .meter
    case .kilometer: .kilometer
    case .mile: .mile
    case .yard: .yard
    case .foot: .foot
    }
  }
}

extension SocketMessage.WorkoutStep.Kind {

  var hkKind: WorkoutStep.Kind {
    switch self {
    case .exercise: .exercise
    case .rest: .rest
    }
  }
}
