//
//  WorkoutsTabView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import CoreHealth
import HealthKit

struct WorkoutsTabView: View {
  @EnvironmentObject var workoutManager: WorkoutManager

  @State private var recentWorkoutTypes: [HKWorkoutActivityType] = []
  @State private var showAllWorkouts = false
  @State private var error: Error?

  private let healthStoreFetcher = HealthStoreFetcher.shared

  // Default workout types if no history
  private static let defaultWorkoutTypes: [HKWorkoutActivityType] = [
    .running, .walking, .cycling, .traditionalStrengthTraining, .yoga
  ]

  var body: some View {
    NavigationStack {
      List {
        ForEach(displayedWorkoutTypes, id: \.self) { workoutType in
          WorkoutCell(workoutType: workoutType)
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
      .listStyle(.carousel)
      .navigationTitle("Start a Workout")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            showAllWorkouts = true
          } label: {
            Image(systemName: "plus")
          }
        }
      }
      .alert(error: $error)
      .task {
        await loadRecentWorkoutTypes()
      }
    }
    .sheet(isPresented: $showAllWorkouts) {
      WorkoutCategoryView()
    }
  }

  private var displayedWorkoutTypes: [HKWorkoutActivityType] {
    recentWorkoutTypes.isEmpty ? Self.defaultWorkoutTypes : recentWorkoutTypes
  }

  private func loadRecentWorkoutTypes() async {
    let workouts = await healthStoreFetcher.fetchWorkouts(
      dateRange: .trailingDays(from: .now, numberOfDays: 90),
      limit: 50
    )

    // Get unique workout types, maintaining order of most recent
    var seenTypes = Set<HKWorkoutActivityType>()
    var uniqueTypes = [HKWorkoutActivityType]()

    for workout in workouts {
      let type = workout.workoutActivityType
      if !seenTypes.contains(type) {
        seenTypes.insert(type)
        uniqueTypes.append(type)
      }
      if uniqueTypes.count >= 5 {
        break
      }
    }

    await MainActor.run {
      recentWorkoutTypes = uniqueTypes
    }
  }

  private func startWorkout(workoutType: HKWorkoutActivityType) async throws {
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = workoutType
    configuration.locationType = .unknown

    try await workoutManager.startWorkout(
      workoutConfiguration: configuration,
      shouldMirror: false
    )
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutsTabView()
  }
}
