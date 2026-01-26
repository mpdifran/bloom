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
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  private let healthStoreFetcher = HealthStoreFetcher.shared

  // Default variants if no history
  private static let defaultVariants: [WorkoutVariant] = [
    .outdoorRunning,
    .outdoorWalking,
    .outdoorCycling,
    .simple(.traditionalStrengthTraining),
    .simple(.yoga)
  ]

  var body: some View {
    NavigationStack {
      List {
        ForEach(displayedVariants) { variant in
          WorkoutVariantCell(variant: variant)
            .onTapGesture {
              startWorkout(variant: variant)
            }
        }
      }
      .listStyle(.carousel)
      .navigationTitle("Start a Workout")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            presentedSheet = WorkoutPickerView() { workoutVariant in
              startWorkout(variant: workoutVariant)
            }.asAny
          } label: {
            Image(systemName: "plus")
          }
        }
      }
      .task {
        await loadRecentVariants()
      }
    }
    .sheet($presentedSheet)
    .alert(error: $error)
  }
}

private extension WorkoutsTabView {

  var displayedVariants: [WorkoutVariant] {
    recentVariants.isEmpty ? Self.defaultVariants : recentVariants
  }

  func loadRecentVariants() async {
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

  func startWorkout(variant: WorkoutVariant) {
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = variant.activityType
    configuration.locationType = variant.locationType

    if variant.activityType == .swimming {
      configuration.swimmingLocationType = variant.locationType == .indoor ? .pool : .openWater
    }

    Task {
      do {
        try await workoutManager.startWorkout(
          workoutConfiguration: configuration,
          shouldMirror: false
        )
      } catch {
        await MainActor.run {
          self.error = error
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutsTabView()
  }
}
