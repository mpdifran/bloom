//
//  WorkoutPickerView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import CoreHealth
import HealthKit
import AppUI

// MARK: - All Workouts Sheet

struct WorkoutPickerView: View {
  let pickedWorkout: (WorkoutVariant) -> Void

  @ObservedObject private var pinnedWorkoutsManager = PinnedWorkoutsManager.shared
  @State private var presentedNavigationDestination: AnyView?

  private var starredVariants: [WorkoutVariant] {
    pinnedWorkoutsManager.pinnedWorkoutIds.compactMap { WorkoutVariant.from(id: $0) }
  }

  var body: some View {
    NavigationStack {
      List {
        if !starredVariants.isEmpty {
          WorkoutCategoryCell(
            title: String(localized: "Starred Workouts", comment: "Workout picker section for pinned workouts"),
            workoutVariants: starredVariants
          )
          .onTapGesture {
            presentedNavigationDestination = StarredWorkoutsDetailsView(
              workoutVariants: starredVariants,
              pickedWorkout: pickedWorkout
            ).asAny
          }
        }

        ForEach(WorkoutCategory.allCases) { category in
          WorkoutCategoryCell(
            title: category.displayName,
            workoutVariants: category.workoutVariants
          )
          .onTapGesture {
            presentedNavigationDestination = WorkoutCategoryDetailsView(
              workoutCategory: category,
              pickedWorkout: pickedWorkout
            ).asAny
          }
        }
      }
      .listStyle(.carousel)
      .navigationDestination($presentedNavigationDestination)
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      WorkoutPickerView() { _ in

      }
    }
  }
}
