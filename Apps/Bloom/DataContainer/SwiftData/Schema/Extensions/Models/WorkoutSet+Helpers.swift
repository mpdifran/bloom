//
//  WorkoutSet+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import Foundation
import HealthKit

public extension WorkoutSet {
  var appleWorkoutType: HKWorkoutActivityType {
    get {
      HKWorkoutActivityType(rawValue: UInt(rawAppleWorkoutType ?? "") ?? 0) ?? .other
    }
    set {
      rawAppleWorkoutType = "\(newValue.rawValue)"
    }
  }

  var format: Format {
    get {
      Format(rawValue: rawFormat) ?? .standard
    }
    set {
      rawFormat = newValue.rawValue
    }
  }

  var orderedExercises: [WorkoutExercise] {
    exercises?.sorted(keyPath: \.index) ?? []
  }

  var representativeDuration: TimeInterval {
    if let duration {
      return duration * Double(numberOfSets)
    } else {
      let duration = exercises?.reduce(0) { partialResult, exercise in
        partialResult + exercise.duration
      } ?? 0

      return duration * Double(numberOfSets)
    }
  }

  var setsDescription: String {
    if numberOfSets == 1 {
      return "1 Set"
    }
    return "\(numberOfSets) Sets"
  }

  var exercisesCountDescription: String {
    let count = exercises?.count ?? 0
    if count == 1 {
      return "1 Exercise"
    }
    return "\(count) Exercises"
  }

  var exercisesDescription: String {
    guard let exercises else { return "" }

    let exerciseNames = exercises.map(\.title)
    return ListFormatter.localizedString(byJoining: exerciseNames)
  }

  var durationDescription: String {
    DateFormatter.timeIntervalHourMinuteShort.string(from: DateComponents(second: Int(representativeDuration))) ?? ""
  }
}

public extension WorkoutSet {
  enum Format: String, CaseIterable {
    case warmup
    case standard
    case amrap
    case emom
    case tabata
    case roundsForTime
    case coolDown

    public var name: String {
      switch self {
      case .warmup:
        "Warm-Up"
      case .standard:
        "Standard"
      case .amrap:
        "AMRAP"
      case .emom:
        "EMOM"
      case .tabata:
        "Tabata"
      case .roundsForTime:
        "RFT"
      case .coolDown:
        "Cool-Down"
      }
    }
  }
}
