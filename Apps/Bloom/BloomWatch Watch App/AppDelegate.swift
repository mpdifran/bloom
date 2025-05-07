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
        try await WorkoutManager.shared.startWorkout(workoutConfiguration: workoutConfiguration)
      } catch {
        print(error)
      }
    }
  }
}
