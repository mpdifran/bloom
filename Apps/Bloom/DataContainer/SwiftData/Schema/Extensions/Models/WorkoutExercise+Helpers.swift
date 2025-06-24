//
//  WorkoutExercise+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-02.
//

import Foundation
import HealthKit

public extension WorkoutExercise {
  
  var kind: Kind {
    get {
      Kind(rawValue: rawKind) ?? .exercise
    }
    set {
      rawKind = newValue.rawValue
    }
  }

  var distanceUnit: DistanceUnit? {
    get {
      DistanceUnit(rawValue: rawDistanceUnit ?? "")
    }
    set {
      rawDistanceUnit = newValue?.rawValue
    }
  }

  var distanceQuantity: HKQuantity? {
    guard let distance, let distanceUnit else { return nil }

    return HKQuantity(unit: distanceUnit.hkUnit, doubleValue: distance)
  }

  var repsDescription: String? {
    guard let numberOfReps else { return nil }

    return "\(numberOfReps) Reps"
  }

  var isTimeBased: Bool {
    numberOfReps == nil && (distance == nil || distanceUnit == nil)
  }
}

public extension WorkoutExercise {
  enum Kind: String, CaseIterable {
    case exercise
    case stretch
  }

  enum DistanceUnit: String {
    case meter
    case kilometer
    case mile
    case yard
    case foot
  }
}

public extension WorkoutExercise.DistanceUnit {

  var hkUnit: HKUnit {
    switch self {
    case .meter:
        .meter()
    case .kilometer:
        .meterUnit(with: .kilo)
    case .mile:
        .mile()
    case .yard:
        .yard()
    case .foot:
        .foot()
    }
  }
}
