//
//  WorkoutController.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import HealthKit
import CoreHealth

final actor WorkoutController {
  static let shared = WorkoutController()

  private init() { }
}

extension WorkoutController {

  func startWorkout(type: HKWorkoutActivityType) async throws {
//    try await WorkoutManager.shared.startWatchWorkout(workoutType: type)
  }

  func resumeWorkout() async throws {
//    await WorkoutManager.shared.session?.resume()
  }

  func pauseWorkout() async throws {
//    await WorkoutManager.shared.session?.pause()
  }

  func endWorkout() async throws {
//    await WorkoutManager.shared.session?.end()
  }
}
