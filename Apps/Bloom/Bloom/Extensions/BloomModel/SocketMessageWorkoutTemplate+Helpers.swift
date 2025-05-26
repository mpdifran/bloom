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

  var equipmentDescription: String {
    ListFormatter.localizedString(byJoining: requiredEquipment.map(\.name))
  }
}
