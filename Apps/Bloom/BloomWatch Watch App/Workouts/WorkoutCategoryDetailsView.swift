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
      ForEach(workoutCategory.workoutTypes, id: \.self) { workoutType in
        WorkoutCell(workoutType: workoutType)
          .onTapGesture {
            Task {
              do {
                try await startWorkout(workoutType: workoutType)
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

  func startWorkout(workoutType: HKWorkoutActivityType) async throws {
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
    WorkoutCategoryDetailsView(workoutCategory: .cardioEndurance)
  }
}
