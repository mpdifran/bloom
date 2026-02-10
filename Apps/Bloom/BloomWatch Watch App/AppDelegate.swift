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
    Task { @MainActor in
      do {
        WorkoutManager.shared.resetWorkout()
        WorkoutManager.shared.heartRateZones = HeartRateZoneSettingsProvider.shared.buildHeartRateZones()
        try await WorkoutManager.shared.prepareWorkout(
          workoutConfiguration: workoutConfiguration,
          shouldMirror: true
        )
      } catch {
        print(error)
      }
    }
  }

  func handleActiveWorkoutRecovery() {
    Task { @MainActor in
      do {
        WorkoutManager.shared.heartRateZones = HeartRateZoneSettingsProvider.shared.buildHeartRateZones()
        try await WorkoutManager.shared.handleActiveWorkoutRecovery()
      } catch {
        print("Error handling active workout recovery: \(error)")
      }
    }
  }
}
