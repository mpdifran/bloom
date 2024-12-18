//
//  WorkoutSummationCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-09.
//

import SwiftUI
import HealthKit

struct WorkoutSummationCell: View {
    let workoutSummation: WorkoutSummation

    var body: some View {
        HStack {
            Image(systemName: workoutSummation.activityType.systemImage)
                .font(.largeTitle)
                .minimumScaleFactor(0.3)
                .foregroundStyle(.green)
                .frame(width: 60)

            VStack(alignment: .leading) {
                Text(workoutSummation.activityType.name)
                    .font(.title3)
                    .bold()
                Text("\(workoutSummation.instances) \(workoutSummation.instances == 1 ? "time" : "times")")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.leading)

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(workoutSummation.totalCalories.format())")
                    .font(.title2)
                    .bold()
                    .fontDesign(.rounded)
                Text("CALS")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .bold()
                    .fontDesign(.rounded)
            }
            DisclosureIndicator()
        }
        .cardContainer(fill: .background.secondary)
    }
}

#Preview {
    ScrollView {
        VStack {
            WorkoutSummationCell(
                workoutSummation: .init(
                    activityType: .cycling,
                    totalCalories: 1342,
                    instances: 5
                )
            )
            WorkoutSummationCell(
                workoutSummation: .init(
                    activityType: .traditionalStrengthTraining,
                    totalCalories: 832,
                    instances: 2
                )
            )
        }
        .padding()
    }
}
