//
//  WorkoutCategoryDetailsView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import HealthKit
import CoreHealth

struct WorkoutCategoryDetailsView: View {
  let workoutCategory: WorkoutCategory

  @EnvironmentObject var workoutManager: WorkoutManager
  @Environment(\.dismiss) private var dismiss

  @State private var error: Error?

  var body: some View {
    List {
      ForEach(workoutCategory.workoutVariants) { variant in
        WorkoutVariantCell(variant: variant)
          .onTapGesture {
            Task {
              do {
                try await startWorkout(variant: variant)
                dismiss()
              } catch {
                self.error = error
              }
            }
          }
      }
    }
    .listStyle(.carousel)
    .alert(error: $error)
  }
}

private extension WorkoutCategoryDetailsView {

  func startWorkout(variant: WorkoutVariant) async throws {
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
    WorkoutCategoryDetailsView(workoutCategory: .cardioEndurance)
  }
}
