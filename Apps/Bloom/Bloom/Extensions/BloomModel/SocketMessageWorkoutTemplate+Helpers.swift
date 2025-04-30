//
//  SocketMessageWorkoutTemplate+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import Foundation
import BloomModel

extension SocketMessage.WorkoutTemplate {

  var equipmentDescription: String {
    ListFormatter.localizedString(byJoining: requiredEquipment.map(\.name))
  }
}
