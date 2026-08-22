//
//  WorkoutCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import SFSafeSymbols
import SwiftUI
import HealthKit
import CoreHealth

struct WorkoutCell: View {
  let workout: HKWorkout

  @State private var effortScore: Double?

  var body: some View {
    HStack {
      WorkoutIcon(workoutType: workout.workoutActivityType)

      VStack(alignment: .leading) {
        HStack(alignment: .top) {
          Text(workout.displayName())
            .font(.headline)
            .bold()
            .fontDesign(.rounded)
            .multilineTextAlignment(.leading)

          Spacer(minLength: 0)

          HStack {
            Text(workout.startDate, formatter: DateFormatter.justRelativeDateMedium)
            DisclosureIndicator()
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }

        HStack {
          if let formattedDuration = DateFormatter.timeIntervalHourMinuteSecondPadded.string(from: workout.duration) {
            WorkoutStatView(stat: "\(formattedDuration)")
              .tint(.mutedYellow)
          }

          WorkoutStatView(stat: "\(workout.totalEnergyBurned.displayString(for: .largeCalorie(), formatter: .noDecimalPlaces))")
            .tint(.mutedPink)

          if let distance = workout.totalDistanceWalkingRunningCycling {
            WorkoutStatView(stat: "\(distance.displayString(for: .meterUnit(with: .kilo), formatter: .twoDecimalPlaces))")
              .tint(.mutedLightBlue)
          }

          Spacer(minLength: 0)
        }

        if let effortScore {
          let category = WorkoutEffortCategory(effortScore: effortScore)
          HStack(spacing: 4) {
            Text("\(Int(effortScore.rounded()))")
              .font(.caption2)
              .bold()
              .fontDesign(.rounded)
              .foregroundStyle(.white)
              .frame(width: 20, height: 20)
              .background(category.color, in: Circle())

            Text(category.displayName)
              .font(.caption)
              .bold()
              .fontDesign(.rounded)
              .foregroundStyle(category.color)
          }
        }
      }
    }
    .cardContainer()
    .task {
      effortScore = await HealthStoreFetcher.shared.fetchWorkoutEffortScore(for: workout)
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        WorkoutCell(
          workout: HKWorkout(
            activityType: .americanFootball,
            start: Date().addingTimeInterval(-3000),
            end: .now
          )
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
