//
//  MultiWorkoutSummaryView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-03-31.
//

import SwiftUI
import HealthKit
import CoreHealth

struct MultiWorkoutSummaryView: View {
  let segments: [CompletedWorkoutSegment]
  let onDismiss: () -> Void

  @EnvironmentObject var workoutManager: WorkoutManager
  @State private var effortScores: [UUID: Int] = [:]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 8) {
          sessionTotals

          ForEach(segments) { segment in
            workoutSegmentCell(segment)
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
      .navigationTitle("Summary")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton(performDismiss: onDismiss)
        }
      }
    }
  }
}

// MARK: - Session Totals

private extension MultiWorkoutSummaryView {

  var sessionTotals: some View {
    VStack {
      SummaryMetricView(title: "Total Time", value: totalTimeString)
        .tint(.mutedYellow)

      SummaryMetricView(title: "Total Energy", value: totalEnergyString)
        .tint(.mutedPink)
    }
  }

  var totalTimeString: String {
    let total = segments.reduce(0) { $0 + $1.workout.duration }
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.zeroFormattingBehavior = .pad
    return formatter.string(from: total) ?? ""
  }

  var totalEnergyString: String {
    let total = segments.reduce(0.0) { sum, segment in
      sum + segment.workout.totalEnergyBurned.doubleValue(for: .largeCalorie())
    }
    return HKQuantity(unit: .largeCalorie(), doubleValue: total)
      .displayString(for: .largeCalorie())
  }
}

// MARK: - Workout Segment Cell

private extension MultiWorkoutSummaryView {

  func workoutSegmentCell(_ segment: CompletedWorkoutSegment) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        WorkoutIcon(workoutType: segment.workout.workoutActivityType, scale: .small)

        VStack(alignment: .leading, spacing: 2) {
          Text(segment.workout.displayName())
            .font(.headline)
            .bold()
            .fontDesign(.rounded)
            .lineLimit(1)

          HStack(spacing: 12) {
            Text(segment.workout.totalTimeString)
              .font(.caption)
              .foregroundStyle(.mutedYellow)

            Text(segment.workout.activeEnergyBurned.displayString(for: .largeCalorie()))
              .font(.caption)
              .foregroundStyle(.mutedPink)
          }
        }

        Spacer()
      }

      NavigationLink {
        WorkoutEffortPickerView(workout: segment.workout) { score in
          effortScores[segment.id] = score
        }
      } label: {
        effortLabel(for: segment)
      }
      .buttonStyle(.plain)
    }
    .padding(8)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(.background.secondary)
    }
  }

  @ViewBuilder
  func effortLabel(for segment: CompletedWorkoutSegment) -> some View {
    if let score = effortScores[segment.id] {
      let category = WorkoutEffortCategory(effortScore: Double(score))
      HStack(spacing: 6) {
        Text("\(score)")
          .font(.caption2)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.white)
          .frame(width: 18, height: 18)
          .background(category.color, in: Circle())

        Text(category.rawValue)
          .font(.caption)
          .bold()
          .fontDesign(.rounded)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    } else {
      Text("Rate Effort")
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.gray)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
  }
}

#Preview {
  PreviewEnvironment {
    MultiWorkoutSummaryView(
      segments: [
        CompletedWorkoutSegment(
          workout: HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: Date().addingTimeInterval(-3600),
            end: Date().addingTimeInterval(-1800)
          ),
          zoneDurations: [0, 120, 300, 180, 60, 0]
        ),
        CompletedWorkoutSegment(
          workout: HKWorkout(
            activityType: .highIntensityIntervalTraining,
            start: Date().addingTimeInterval(-1800),
            end: .now
          ),
          zoneDurations: [0, 60, 120, 240, 180, 30]
        ),
      ],
      onDismiss: {}
    )
  }
}
