//
//  WorkoutSessionStateChange.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-05.
//

import Foundation
import HealthKit

struct WorkoutSessionSateChange {
  let newState: HKWorkoutSessionState
  let date: Date
}
