//
//  Workout+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import Foundation
import HealthKit

public extension WorkoutTemplate {
  var appleWorkoutType: HKWorkoutActivityType {
    get {
      HKWorkoutActivityType(rawValue: UInt(rawAppleWorkoutType) ?? 0) ?? .other
    }
    set {
      rawAppleWorkoutType = "\(newValue.rawValue)"
    }
  }

  var stepsDescription: String {
    guard let steps else { return "" }

    if steps.count == 1 {
      return "1 exercise"
    }
    return "\(steps.count) exercises"
  }

  var durationDescription: String {
    guard let steps else { return "" }

    let duration = steps
      .reduce(0) { (result, step) in
        result + step.duration
      }
    return DateFormatter.timeIntervalHourMinuteShort.string(from: DateComponents(second: Int(duration))) ?? ""
  }

  var equipmentDescription: String {
    ListFormatter.localizedString(byJoining: equipment.map(\.name))
  }

  var equipment: [Equipment] {
    rawRequiredEquipment.compactMap({ Equipment(rawValue: $0) })
  }

  enum Equipment: String, CaseIterable, Codable, Identifiable {
    case dumbbells
    case barbell
    case kettlebell
    case batBell
    case chinUpBar
    case treadmill
    case stationaryBike
    case bike
    case elliptical
    case rowingMachine
    case skiMachine
    case yogaMat
    case resistanceBand
    case weightedVest

    public var id: Self { self }
  }
}

public extension WorkoutTemplate.Equipment {

  var name: String {
    switch self {
    case .dumbbells:
      "Dumbbells"
    case .barbell:
      "Barbell"
    case .kettlebell:
      "Kettlebell"
    case .batBell:
      "Batbell"
    case .chinUpBar:
      "Chin-up Bar"
    case .treadmill:
      "Treadmill"
    case .stationaryBike:
      "Stationary Bike"
    case .bike:
      "Bike"
    case .elliptical:
      "Elliptical"
    case .rowingMachine:
      "Rowing Machine"
    case .skiMachine:
      "Ski Machine"
    case .yogaMat:
      "Yoga Mat"
    case .resistanceBand:
      "Resistance Band"
    case .weightedVest:
      "Weighted Vest"
    }
  }
}
