//
//  WorkoutSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-05.
//

import SwiftUI

struct WorkoutSummaryCell: View {
    let workoutSummaries: [WorkoutSummary]

    var body: some View {
        Section {
            SleepProgramSectionHeader(
                title: "Workouts",
                subtitle: "Last Two Weeks",
                systemImage: "figure.run"
            )

            HStack {
                VStack(alignment: .leading) {
                    LabelledMetricView(
                        label: "Amount",
                        value: "\(workoutSummaries.count) Workouts"
                    )
                    .tint(.yellow)

                    LabelledMetricView(
                        label: "Total Duration",
                        value: "\(String(format: "%.0f", workoutDurationSumMinutes)) min"
                    )
                    .tint(.green)

                    LabelledMetricView(
                        label: "Total Energy Burned",
                        value: "\(String(format: "%.0f", energyBurned)) CAL"
                    )
                    .tint(.pink)
                }

                Spacer()

                ProgressRingView(
                    progress: .constant(workoutDurationScore),
                    dimension: 80,
                    color: .green
                )
            }

            HStack {
                LabelledMetricView(
                    label: "Average",
                    value: "\(workoutAverageDuration) min / day"
                )
                .tint(.secondary)

                Spacer()

                LabelledMetricView(
                    label: "Goal",
                    value: "30 min / day"
                )
            }
        }
        .tint(.green)
    }
}

private extension WorkoutSummaryCell {

    var workoutSummary: String {
        if workoutDurationScore < 0.5 {
            "More daily exercise can help with a good night sleep."
        } else if workoutDurationScore < 1 {
            "Aiming for a bit more exercise each day will help with your sleep."
        } else {
            "You're getting at least 30 minutes of exercise, great job!"
        }
    }

    var workoutDurationScore: CGFloat {
        workoutDurationSumMinutes / 14 / 30
    }

    var workoutDurationSumMinutes: TimeInterval {
        workoutSummaries.reduce(0) { partialResult, workoutSummary in
            partialResult + workoutSummary.durationSeconds
        } / 60
    }

    var workoutAverageDuration: String {
        let average = workoutDurationSumMinutes / 14

        return String(format: "%.0f", average)
    }

    var energyBurned: Double {
        workoutSummaries.reduce(0) { partialResult, workoutSummary in
            partialResult + workoutSummary.caloriesBurned
        } / 1000
    }
}

#Preview {
    List {
        WorkoutSummaryCell(
            workoutSummaries: [
                .init(
                    activity: "Rock Climbing",
                    startDate: .now,
                    durationSeconds: 2894,
                    caloriesBurned: 234000,
                    distance: 0
                )
            ]
        )
    }
}
