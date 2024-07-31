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

    @ObservedObject private var vitalsViewModel = VitalsViewModel.shared

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

            if let targetVitalModel {
                TargetVitalComponentView(vital: targetVitalModel)
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

    var targetVitalModel: VitalModel? {
        vitalsViewModel.vitals.first(where: { $0.id == goal.vitalKind })
    }

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
                vitalKind: .sleepQuality
            ),
            index: 0
        )
    }
}
