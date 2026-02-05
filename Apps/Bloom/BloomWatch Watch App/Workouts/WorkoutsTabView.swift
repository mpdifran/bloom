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
  @ObservedObject private var pinnedWorkoutsManager = PinnedWorkoutsManager.shared
  @ObservedObject private var locationManager = LocationManager.shared

  @State private var recentVariants: [WorkoutVariant] = []
  @State private var presentedSheet: AnyView?
  @State private var error: Error?
  @State private var resetController = NavigationResetController.shared

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
          WorkoutVariantCell(variant: variant, isPinned: pinnedWorkoutsManager.isPinned(variant))
            .onTapGesture {
              startWorkout(variant: variant)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
              if pinnedWorkoutsManager.isPinned(variant) {
                Button(role: .destructive) {
                  pinnedWorkoutsManager.unpin(variant)
                } label: {
                  Label("Un-Star", systemSymbol: .starSlashFill)
                    .tint(.mutedOrange)
                }
              } else {
                Button {
                  pinnedWorkoutsManager.pin(variant)
                } label: {
                  Label("Star", systemSymbol: .starFill)
                    .tint(.mutedOrange)
                }
              }
            }
        }

        settingsCell
      }
      .listStyle(.carousel)
      .navigationTitle("Workouts")
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
    .onChange(of: resetController.resetTrigger) {
      presentedSheet = nil
    }
  }
}

private extension WorkoutsTabView {

  var displayedVariants: [WorkoutVariant] {
    let baseVariants = recentVariants.isEmpty ? Self.defaultVariants : recentVariants

    // Get pinned variants in their stored order
    let pinnedVariants = pinnedWorkoutsManager.pinnedWorkoutIds
      .compactMap { WorkoutVariant.from(id: $0) }

    // Filter base variants to exclude pinned ones
    let unpinnedBaseVariants = baseVariants.filter { base in
      !pinnedWorkoutsManager.isPinned(base)
    }

    // Pinned first (in order), then unpinned base variants
    return pinnedVariants + unpinnedBaseVariants
  }

  var settingsCell: some View {
    HStack(spacing: 10) {
      Image(systemName: "gear")
        .font(.title2)
        .foregroundStyle(.secondary)
      Text("Settings")
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
      Spacer()
    }
    .padding(.vertical, 10)
    .selectable()
    .onTapGesture {
      presentedSheet = WorkoutSettingsView().asAny
    }
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
    // Request location permission for outdoor workouts (needed for route recording)
    if variant.locationType == .outdoor && !locationManager.isAuthorized {
      locationManager.requestWhenInUseAuthorization()
    }

    let configuration = HKWorkoutConfiguration()
    configuration.activityType = variant.activityType
    configuration.locationType = variant.locationType

    if variant.activityType == .swimming {
      configuration.swimmingLocationType = variant.locationType == .indoor ? .pool : .openWater
    }

    Task {
      do {
        try await workoutManager.prepareWorkout(
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
