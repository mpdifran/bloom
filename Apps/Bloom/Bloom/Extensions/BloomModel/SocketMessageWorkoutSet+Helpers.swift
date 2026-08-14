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

  var representativeDuration: TimeInterval {
    if format == .tabata {
      return 240
    }
    if let duration {
      return duration * Double(numberOfSets)
    } else {
      let duration = exercises.reduce(0) { partialResult, exercise in
        partialResult + exercise.duration
      }

      return duration * Double(numberOfSets)
    }
  }

  var setsDescription: String {
    if numberOfSets == 1 {
      return "1 Set"
    }
    return "\(numberOfSets) Sets"
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
    case .cooldown: .coolDown
    }
  }

  var name: String {
    switch self {
    case .warmup:
      String(localized: "Warm-Up", comment: "Display name for format")
    case .standard:
      String(localized: "Standard", comment: "Display name for format")
    case .amrap:
      String(localized: "AMRAP", comment: "Display name for format")
    case .emom:
      String(localized: "EMOM", comment: "Display name for format")
    case .tabata:
      String(localized: "Tabata", comment: "Display name for format")
    case .cooldown:
      String(localized: "Cool-Down", comment: "Display name for format")
    }
  }
}
