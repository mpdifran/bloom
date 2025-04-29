//
//  WorkoutStep+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import Foundation
import HealthKit

public extension WorkoutStep {
  var overrideAppleWorkoutType: HKWorkoutActivityType? {
    get {
      guard let rawOverrideAppleWorkoutType else { return nil }

      return HKWorkoutActivityType(rawValue: UInt(rawOverrideAppleWorkoutType) ?? 0)
    }
    set {
      if let newValue {
        rawOverrideAppleWorkoutType = "\(newValue.rawValue)"
      } else {
        rawOverrideAppleWorkoutType = ""
      }
    }
  }

  var kind: WorkoutStep.Kind {
    get {
      WorkoutStep.Kind(rawValue: rawKind) ?? .exercise
    }
    set {
      rawKind = newValue.rawValue
    }
  }

  var distanceUnit: DistanceUnit? {
    get {
      WorkoutStep.DistanceUnit(rawValue: rawDistanceUnit ?? "")
    }
    set {
      rawDistanceUnit = newValue?.rawValue
    }
  }

  var distanceQuantity: HKQuantity? {
    guard let distance, let distanceUnit else { return nil }

    return HKQuantity(unit: distanceUnit.hkUnit, doubleValue: distance)
  }

  var durationDescription: String {
    DateFormatter.timeIntervalHourMinuteShort.string(from: DateComponents(second: Int(duration))) ?? ""
  }
}

public extension WorkoutStep.DistanceUnit {

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
