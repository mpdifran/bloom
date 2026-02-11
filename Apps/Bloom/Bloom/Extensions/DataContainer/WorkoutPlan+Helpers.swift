//
//  WorkoutPlan+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-03.
//

import DataContainer
import HealthKit
import SFSafeSymbols

extension WorkoutPlan {

  var representativeSystemSymbol: SFSymbol {
    SFSymbol(rawValue: representativeAppleWorkoutType.systemImage)
  }

  var displayWorkoutTypes: [HKWorkoutActivityType] {
    let activityTypes = orderedSets
      .filter { $0.format != .warmup && $0.format != .coolDown }
      .map(\.appleWorkoutType)

    guard !activityTypes.isEmpty else { return [.other] }

    var seen = Set<HKWorkoutActivityType>()
    let uniqueTypes = activityTypes.filter { seen.insert($0).inserted }

    if activityTypes.count >= 3 {
      if uniqueTypes.count >= 3 {
        return Array(uniqueTypes.prefix(3))
      } else if uniqueTypes.count == 2 {
        return [uniqueTypes[0], uniqueTypes[1], uniqueTypes[0]]
      } else {
        return Array(repeating: uniqueTypes[0], count: 3)
      }
    } else {
      return activityTypes
    }
  }
}
