//
//  WorkoutPlan+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import Foundation
import HealthKit

public extension WorkoutPlan {

  var representativeAppleWorkoutType: HKWorkoutActivityType {
    sets?.first(where: { $0.format != .warmup && $0.format != .coolDown })?.appleWorkoutType ?? .other
  }

  var setsDescription: String {
    guard let setsNames = sets?.map({ $0.title }) else { return "" }

    return ListFormatter.localizedString(byJoining: setsNames)
  }

  var durationDescription: String {
    guard let sets else { return "" }

    let duration = sets.reduce(0) { partialResult, set in
      partialResult + set.representativeDuration
    }

    return DateFormatter.timeIntervalHourMinuteShort.string(from: DateComponents(second: Int(duration))) ?? ""
  }

  var equipmentDescription: String {
    ListFormatter.localizedString(byJoining: equipment.map(\.name))
  }

  var equipment: [Equipment] {
    rawRequiredEquipment.compactMap({ Equipment(rawValue: $0) })
  }

  var orderedSets: [WorkoutSet] {
    sets?.sorted(keyPath: \.index) ?? []
  }

  func expandedExerciseSets() -> [WorkoutExerciseSet] {
    var exerciseSets = [WorkoutExerciseSet]()
    for set in orderedSets {
      for setCount in 0 ..< set.numberOfSets {
        for exercise in set.orderedExercises {
          let exerciseSet = WorkoutExerciseSet(
            set: set,
            exercise: exercise,
            setNumber: setCount
          )
          exerciseSets.append(exerciseSet)

          let restSet = WorkoutExerciseSet(
            set: set,
            rest: set.restBetweenExercises,
            setNumber: setCount
          )
          exerciseSets.append(restSet)
        }
      }
    }
    return exerciseSets
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

public extension WorkoutPlan.Equipment {

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
