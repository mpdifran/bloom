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

  @State private var recentVariants: [WorkoutVariant] = []
  @State private var showAllWorkouts = false
  @State private var error: Error?

  private let healthStoreFetcher = HealthStoreFetcher.shared

  // Default variants if no history
  private static let defaultVariants: [WorkoutVariant] = [
    .outdoorRunning, .outdoorWalking, .outdoorCycling,
    .simple(.traditionalStrengthTraining), .simple(.yoga)
  ]

  var body: some View {
    NavigationStack {
      List {
        ForEach(displayedVariants) { variant in
          WorkoutVariantCell(variant: variant)
            .onTapGesture {
              Task {
                do {
                  try await startWorkout(variant: variant)
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
        await loadRecentVariants()
      }
    }
    .sheet(isPresented: $showAllWorkouts) {
      WorkoutCategoryView()
    }
  }

  private var displayedVariants: [WorkoutVariant] {
    recentVariants.isEmpty ? Self.defaultVariants : recentVariants
  }

  private func loadRecentVariants() async {
    let workouts = await healthStoreFetcher.fetchWorkouts(
      dateRange: .trailingDays(from: .now, numberOfDays: 90),
      limit: 50
    )

    // Get unique variants, maintaining order of most recent
    var seenVariantIds = Set<String>()
    var uniqueVariants = [WorkoutVariant]()

    for workout in workouts {
      let hasRoute = await healthStoreFetcher.workoutHasRoute(workout)
      let variant = WorkoutVariant.from(workout: workout, hasRoute: hasRoute)

      if !seenVariantIds.contains(variant.id) {
        seenVariantIds.insert(variant.id)
        uniqueVariants.append(variant)
      }
      if uniqueVariants.count >= 5 {
        break
      }
    }

    await MainActor.run {
      recentVariants = uniqueVariants
    }
  }

  private func startWorkout(variant: WorkoutVariant) async throws {
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = variant.activityType
    configuration.locationType = variant.locationType

    if variant.activityType == .swimming {
      configuration.swimmingLocationType = variant.locationType == .indoor ? .pool : .openWater
    }

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
