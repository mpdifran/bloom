//
//  AppDelegate.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-06.
//

import WatchKit
import HealthKit
import SwiftUI
import CoreHealth

class AppDelegate: NSObject, WKApplicationDelegate {

  func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
    Task {
      do {
        WorkoutManager.shared.resetWorkout()
        try await WorkoutManager.shared.startWorkout(
          workoutConfiguration: workoutConfiguration,
          shouldMirror: true
        )
      } catch {
        print(error)
      }
    }
  }

  func handleActiveWorkoutRecovery() {
    Task {
      do {
        try await WorkoutManager.shared.handleActiveWorkoutRecovery()
      } catch {
        print("Error handling active workout recovery: \(error)")
      }
    }
  }
}
