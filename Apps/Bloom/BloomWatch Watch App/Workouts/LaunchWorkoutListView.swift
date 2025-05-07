//
//  LaunchWorkoutListView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2025-05-05.
//

import SwiftUI
import CoreHealth
import HealthKit
import AppUI

struct LaunchWorkoutListView: View {

  @EnvironmentObject var workoutManager: WorkoutManager

  @State private var error: Error?

  var body: some View {
    List {
      ForEach(HKWorkoutActivityType.allCases, id: \.self) { workoutType in
        LaunchWorkoutCell(workoutType: workoutType)
          .onTapGesture {
            Task {
              do {
                try await startWorkout(workoutType: workoutType)
              } catch {
                self.error = error
              }
            }
          }
      }
    }
    .navigationTitle("Workout")
    .alert(error: $error)
  }
}

private extension LaunchWorkoutListView {

  func startWorkout(workoutType: HKWorkoutActivityType) async throws {
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = workoutType
    configuration.locationType = .unknown

    try await workoutManager.startWorkout(workoutConfiguration: configuration)
  }
}

#Preview {
  NavigationStack {
    LaunchWorkoutListView()
  }
}
