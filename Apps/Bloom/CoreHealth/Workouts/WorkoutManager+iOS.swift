//
//  WorkoutManager+iOS.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-05.
//

import Foundation
import HealthKit

#if os(iOS)
extension WorkoutManager {

  func startWatchWorkout(workoutType: HKWorkoutActivityType) async throws {
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = workoutType
    configuration.locationType = .outdoor
    try await healthStore.startWatchApp(toHandle: configuration)
  }

  func retrieveRemoteSession() {
    healthStore.workoutSessionMirroringStartHandler = { mirroredSession in
      Task { @MainActor in
        self.resetWorkout()
        self.session = mirroredSession
        self.session?.delegate = self
        print("Start mirroring remote session: \(mirroredSession)")
      }
    }
  }

  func handleReceivedData(_ data: Data) throws {
    if let elapsedTime = try? JSONDecoder().decode(WorkoutElapsedTime.self, from: data) {
      var currentElapsedTime: TimeInterval = 0
      if session?.state == .running {
        currentElapsedTime = elapsedTime.timeInterval + Date().timeIntervalSince(elapsedTime.date)
      } else {
        currentElapsedTime = elapsedTime.timeInterval
      }
      elapsedTimeInterval = currentElapsedTime
    } else if let statisticsArray = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: HKStatistics.self, from: data) {
      for statistics in statisticsArray {
        updateForStatistics(statistics)
      }
    }
  }
}
#endif
