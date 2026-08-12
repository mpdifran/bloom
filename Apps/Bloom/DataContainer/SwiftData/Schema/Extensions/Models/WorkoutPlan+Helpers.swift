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
    orderedSets.first(where: { $0.format != .warmup && $0.format != .coolDown })?.appleWorkoutType ?? .other
  }

  var setsDescription: String {
    let setsNames = orderedSets.map({ $0.title })

    return ListFormatter.localizedString(byJoining: setsNames)
  }

  var durationDescription: String {

    let duration = orderedSets.reduce(0) { partialResult, set in
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
      for setNumber in 0 ..< set.numberOfSets {
        switch set.format {
        case .warmup, .coolDown:
          for exercise in set.orderedExercises {
            let exerciseSet = WorkoutExerciseSet(
              set: set,
              exercise: exercise,
              setNumber: setNumber
            )
            exerciseSets.append(exerciseSet)
          }
        case .standard:
          for exercise in set.orderedExercises {
            let exerciseSet = WorkoutExerciseSet(
              set: set,
              exercise: exercise,
              setNumber: setNumber
            )
            exerciseSets.append(exerciseSet)

            if set.restBetweenExercises > 0 {
              let restSet = WorkoutExerciseSet(
                set: set,
                rest: set.restBetweenExercises,
                setNumber: setNumber
              )
              exerciseSets.append(restSet)
            }
          }
        case .amrap, .emom, .tabata:
          let exerciseSet = WorkoutExerciseSet(
            set: set,
            exercises: set.orderedExercises,
            format: set.format,
            setNumber: setNumber
          )
          exerciseSets.append(exerciseSet)
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
      String(localized: "Dumbbells", bundle: Bundle.dataContainer)
    case .barbell:
      String(localized: "Barbell", bundle: Bundle.dataContainer)
    case .kettlebell:
      String(localized: "Kettlebell", bundle: Bundle.dataContainer)
    case .batBell:
      String(localized: "Batbell", bundle: Bundle.dataContainer)
    case .chinUpBar:
      String(localized: "Chin-up Bar", bundle: Bundle.dataContainer)
    case .treadmill:
      String(localized: "Treadmill", bundle: Bundle.dataContainer)
    case .stationaryBike:
      String(localized: "Stationary Bike", bundle: Bundle.dataContainer)
    case .bike:
      String(localized: "Bike", bundle: Bundle.dataContainer)
    case .elliptical:
      String(localized: "Elliptical", bundle: Bundle.dataContainer)
    case .rowingMachine:
      String(localized: "Rowing Machine", bundle: Bundle.dataContainer)
    case .skiMachine:
      String(localized: "Ski Machine", bundle: Bundle.dataContainer)
    case .yogaMat:
      String(localized: "Yoga Mat", bundle: Bundle.dataContainer)
    case .resistanceBand:
      String(localized: "Resistance Band", bundle: Bundle.dataContainer)
    case .weightedVest:
      String(localized: "Weighted Vest", bundle: Bundle.dataContainer)
    }
  }
}
