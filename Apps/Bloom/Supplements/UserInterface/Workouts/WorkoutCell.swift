//
//  WorkoutCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import SwiftUI
import HealthKit

struct WorkoutCell: View {
  let workout: HKWorkout

  var body: some View {
    HStack {
      Image(systemName: workout.workoutActivityType.systemImage)
          .font(.largeTitle)
          .minimumScaleFactor(0.3)
          .foregroundStyle(.green)
          .frame(width: 60)

      VStack(alignment: .leading) {
        HStack(alignment: .top) {
          Text(workout.workoutActivityType.name)
            .font(.title3)
            .bold()
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
              .tint(.yellow)
          }

          WorkoutStatView(stat: "\(workout.totalEnergyBurned.displayString(for: .largeCalorie(), formatter: .noDecimalPlaces))")
            .tint(.green)

          if let distance = workout.totalDistanceWalkingRunningCycling {
            WorkoutStatView(stat: "\(distance.displayString(for: .meterUnit(with: .kilo), formatter: .twoDecimalPlaces))")
              .tint(.blue)
          }

          Spacer(minLength: 0)
        }
      }
    }
    .cardContainer()
  }
}

#Preview {
  ScrollView {
    VStack {
      WorkoutCell(
        workout: .init(
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
