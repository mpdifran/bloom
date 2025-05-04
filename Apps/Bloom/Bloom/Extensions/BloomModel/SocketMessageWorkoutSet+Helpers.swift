//
//  SocketMessageWorkoutSet+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-02.
//

import Foundation
import BloomModel
import DataContainer
import HealthKit

extension SocketMessage.WorkoutSet {

  var exercisesDescription: String {
    let exerciseNames = exercises.map(\.title)
    return ListFormatter.localizedString(byJoining: exerciseNames)
  }
}

extension SocketMessage.WorkoutSet.Format {

  var hkFormat: WorkoutSet.Format {
    switch self {
    case .warmup: .warmup
    case .standard: .standard
    case .amrap: .amrap
    case .emom: .emom
    case .tabata: .tabata
    case .roundsForTime: .roundsForTime
    case .coolDown: .coolDown
    }
  }
}
