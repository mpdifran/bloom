//
//  ActiveWorkoutSummaryView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI
import HealthKit
import CoreHealth

struct ActiveWorkoutSummaryView: View {
  let onDismiss: () -> Void

  @EnvironmentObject var workoutManager: WorkoutManager

  var body: some View {
    if let workout = workoutManager.workout {
      ScrollView {
        summaryListView(workout: workout)
          .scenePadding()
      }
      .navigationTitle("Summary")
      .navigationBarTitleDisplayMode(.inline)
    } else {
      ProgressView("Saving Workout")
        .navigationBarHidden(true)
    }
  }

  @ViewBuilder
  private func summaryListView(workout: HKWorkout) -> some View {
    VStack(alignment: .leading) {
      SummaryMetricView(title: "Total Time", value: workout.totalTimeString)
        .foregroundStyle(.yellow)

      SummaryMetricView(title: "Total Energy", value: workout.totalEnergyBurned.displayString(for: .largeCalorie()))
        .foregroundStyle(.pink)

      SummaryMetricView(title: "Avg. Heart Rate", value: workout.averageHeartRate.displayString(for: .bpm()))
        .foregroundStyle(.red)

      Group {
        Text("Activity Rings")
        ActivityRingsView(healthStore: workoutManager.healthStore)
          .frame(width: 50, height: 50)
      }

      Button {
        onDismiss()
      } label: {
        Text("Done")
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    ActiveWorkoutSummaryView {

    }
  }
}
