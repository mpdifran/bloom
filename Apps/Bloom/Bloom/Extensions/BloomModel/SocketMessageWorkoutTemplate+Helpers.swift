//
//  SocketMessageWorkoutTemplate+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import Foundation
import BloomModel
import HealthKit

extension SocketMessage.WorkoutPlan {

  var representativeAppleWorkoutType: HKWorkoutActivityType {
    sets.first(where: { $0.format != .warmup && $0.format != .cooldown })?.appleWorkoutType.hkWorkoutType ?? .other
  }

  var displayWorkoutTypes: [HKWorkoutActivityType] {
    let activityTypes = sets
      .filter { $0.format != .warmup && $0.format != .cooldown }
      .map(\.appleWorkoutType.hkWorkoutType)

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

  var equipmentDescription: String {
    if requiredEquipment.isEmpty {
      return "No equipment required"
    }
    return ListFormatter.localizedString(byJoining: requiredEquipment.map(\.name)) + " required"
  }
}
