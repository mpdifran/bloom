//
//  WorkoutEffortPickerCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-02-11.
//

import SwiftUI
@preconcurrency import HealthKit
import CoreHealth

struct WorkoutEffortPickerCard: View {
  let workout: HKWorkout
  let performDismiss: (() -> Void)?

  @State private var selectedEffort: Int = 5

  var body: some View {
    CardView {
      LargeTitleActionCard("Rate Your Effort") {
        HealthActionCardView(
          sampleTypes: [HKQuantityType(.workoutEffortScore)],
          performDismiss: performDismiss
        ) {
          try await saveEffort()
          return true
        } content: { _, _ in
          VStack(spacing: 24) {
            WorkoutEffortBarView(selectedEffort: $selectedEffort)
              .tint(WorkoutEffortCategory.category(for: selectedEffort).color)
              .padding(.horizontal)

            effortLabel
          }
        }
      }
    }
    .animation(.easeInOut, value: selectedEffort)
    .task {
      if let existingEffort = await HealthStoreFetcher.shared.fetchWorkoutEffortScore(for: workout) {
        selectedEffort = Int(existingEffort.rounded())
      }
    }
  }
}

// MARK: - Components

private extension WorkoutEffortPickerCard {

  var effortLabel: some View {
    HStack {
      Text("Effort")
        .font(.body)
        .bold()

      Spacer()

      Text(WorkoutEffortCategory.category(for: selectedEffort).displayName)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)
    }
    .cardContainer()
  }
}

// MARK: - Save

private extension WorkoutEffortPickerCard {

  func saveEffort() async throws {
    try await HealthStoreModifier.shared.logWorkoutEffort(
      effortScore: Double(selectedEffort),
      for: workout
    )
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      WorkoutEffortPickerCard(
        workout: HKWorkout(
          activityType: .traditionalStrengthTraining,
          start: Date().addingTimeInterval(-3600),
          end: .now
        ),
        performDismiss: nil
      )
    }
  }
}
