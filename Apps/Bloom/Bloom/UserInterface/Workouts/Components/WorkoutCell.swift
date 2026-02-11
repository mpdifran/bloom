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
            Text("\(workout.startDate, formatter: DateFormatter.justRelativeDateMedium)")
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
      }
    }
    .cardContainer()
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
