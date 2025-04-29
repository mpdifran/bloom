//
//  WorkoutController.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import HealthKit

final actor WorkoutController {
  static let shared = WorkoutController()

  private init() { }
}

extension WorkoutController {

  func startWorkout(type: HKWorkoutActivityType) async throws {
    // TODO: Implement
  }

  func resumeWorkout() async throws {
    
  }

  func pauseWorkout() async throws {

  }

  func endWorkout() async throws {
    
  }
}
