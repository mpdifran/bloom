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
      }
      .navigationTitle("Summary")
      .navigationBarTitleDisplayMode(.inline)
      .scenePadding()
    } else {
      ProgressView("Saving Workout")
        .navigationBarHidden(true)
    }
  }

  @ViewBuilder
  private func summaryListView(workout: HKWorkout) -> some View {
    VStack(alignment: .leading) {
      SummaryMetricView(title: "Total Time", value: workout.totalTimeString)
        .tint(.mutedYellow)

      SummaryMetricView(title: "Total Energy", value: workout.totalEnergyBurned.displayString(for: .largeCalorie()))
        .tint(.mutedPink)

      SummaryMetricView(title: "Avg. Heart Rate", value: workout.averageHeartRate.displayString(for: .bpm()))
        .tint(.mutedRed)

      SummaryMetricView(title: "Zone Minutes", value: "\(Int(workoutManager.totalZoneMinutes))")
        .tint(.mutedGreen)

      SummaryMetricView(title: "Heart Rate Zones") {
        MiniHeartRateZoneDistributionView(distribution: zoneDistribution)
      }

      SummaryMetricView(title: "Activity Rings") {
        ActivityRingsView(healthStore: workoutManager.healthStore)
          .frame(width: 50, height: 50)
      }

      Button {
        onDismiss()
      } label: {
        Text("Done")
          .horizontallyCentered()
      }
    }
  }

  private var zoneDistribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution {
    let durations = workoutManager.zoneDurations
    let total = durations.reduce(0, +)

    return WorkoutHeartRateReport.WorkoutHeartZoneDistribution(
      totalDuration: HKQuantity(unit: .second(), doubleValue: total),
      zone1: HKQuantity(unit: .second(), doubleValue: durations[1]),
      zone2: HKQuantity(unit: .second(), doubleValue: durations[2]),
      zone3: HKQuantity(unit: .second(), doubleValue: durations[3]),
      zone4: HKQuantity(unit: .second(), doubleValue: durations[4]),
      zone5: HKQuantity(unit: .second(), doubleValue: durations[5])
    )
  }
}

#Preview {
  PreviewEnvironment {
    ActiveWorkoutSummaryView {

    }
  }
}
