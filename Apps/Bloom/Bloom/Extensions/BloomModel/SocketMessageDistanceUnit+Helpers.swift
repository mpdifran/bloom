//
//  SocketMessageDistanceUnit+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-29.
//

import BloomModel
import HealthKit

extension SocketMessage.WorkoutExercise.DistanceUnit {

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
