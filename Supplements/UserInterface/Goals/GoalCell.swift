//
//  GoalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import HealthKit
import Charts

struct GoalCell: View {
    let goal: GoalModel
    let index: Int

    @State private var currentGoalValue: Double = 0

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: goal.systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(goal.color)
                VStack(alignment: .leading) {
                    Text(goal.title)
                        .font(.title3)
                        .bold()
                    Text(goal.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            barChart

            HStack {
                VStack(alignment: .leading) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(goal.vital.name)
                        .bold()
                }

                Spacer()

                HStack {
                    Text(goal.vital.metricValue)
                        .font(.headline)
                        .bold()
                        .fontDesign(.rounded)
                        .foregroundStyle(goal.vital.color)

                    Group {
                        switch goal.vital.trend {
                        case .increasing:
                            Image(systemName: "chevron.up.circle")
                        case .decreasing:
                            Image(systemName: "chevron.down.circle")
                        case .noTrend:
                            Image(systemName: "minus.circle")
                                .foregroundStyle(.primary, .fill)
                        }
                    }
                    .foregroundStyle(.primary, goal.vital.color)
                    .font(.title)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            }
        }
        .animation(.bouncy(duration: 1).delay(Double(index) * 0.3), value: currentGoalValue)
        .onAppear {
            loadCurrentGoalValue()
        }
    }
}

private extension GoalCell {

    var barChart: some View {
        Chart {
            BarMark(
                x: .value("Current Time", currentGoalValue),
                y: .value("Week", "This Week")
            )
            .foregroundStyle(goal.color)
            .cornerRadius(10)

            RuleMark(
                x: .value("Goal", goal.metric.value)
            )
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(goal.color.opacity(0.5))
        }
        .chartXAxis {
            AxisMarks {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartXScale(
            domain: (0...goal.metric.value * 1.3),
            range: .plotDimension
        )
        .frame(height: 100)
    }
}

private extension GoalCell {

    func loadCurrentGoalValue() {
        switch goal.metric.measurement {
        case .timeInDaylight:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.timeInDaylight)) {
                let value = await HealthManager.shared.fetchThisWeekSumQuantity(for: .timeInDaylight, unit: .minute())
                print(value)
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .walkWheelDistance:
            break
        case .walkWheelDuration:
            break
        case .runWheelDistance:
            break
        case .runWheelDuration:
            break
        case .bikeDistance:
            break
        case .bikeDuration:
            break
        case .walkRunBikeWheelDistance:
            break
        case .walkRunBikeWheelDuration:
            break
        case .stepCount:
            break
        case .meditationMinutes:
            break
        case .bedtimeSoundLevels:
            break
        case .yogaWorkoutDuration:
            break
        case .casualSportWorkoutDuration:
            break
        case .intenseSportWorkoutDuration:
            break
        case .gymTrainingWorkoutDuration:
            break
        case .HIITTrainingWorkoutDuration:
            break
        case .targetHeartRateZoneProportionsZone2:
            break
        case .targetHeartRateZoneProportionsZone3:
            break
        case .targetHeartRateZoneProportionsZone4:
            break
        case .targetHeartRateZoneProportionsZone5:
            break
        }
    }
}

#Preview {
    List {
        GoalCell(
            goal: .init(
                title: "Get More Sunlight",
                systemImage: "sun.max.fill",
                summary: "More sun is good for your body. It also gives you Vitamin D! Aim to get 50 minutes of sunlight this week.",
                color: .orange,
                metric: .init(
                    value: 300,
                    measurement: .timeInDaylight
                ),
                vital: .init(
                    name: "Sleep Quality",
                    systemImage: "moon.zzz",
                    metricValue: "Low",
                    color: .yellow,
                    trend: .decreasing
                )
            ),
            index: 0
        )
    }
}
