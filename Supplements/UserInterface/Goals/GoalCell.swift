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
                    .foregroundStyle(goal.metric.measurement.color)
                VStack(alignment: .leading) {
                    HStack {
                        Text(goal.title)
                            .font(.title3)
                            .bold()
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)

                        VStack(alignment: .trailing) {
                            Text("Due")
                                .foregroundStyle(.secondary)
                                .font(.caption2)
                            Text("\(goal.dueDate, formatter: DateFormatter.justRelativeDateMedium)")
                                .font(.subheadline)
                        }
                    }
                }
            }

            barChart

            Text(goal.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
            .foregroundStyle(goal.metric.measurement.color)
            .cornerRadius(10)

            RuleMark(
                x: .value("Goal", goal.metric.value)
            )
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(goal.metric.measurement.color.opacity(0.5))
        }
        .chartXAxis {
            AxisMarks {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartXScale(
            domain: (0...max(goal.metric.value, currentGoalValue) * 1.3),
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
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }

        case .walkRunDistance:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.distanceWalkingRunning)) {
                let value = await HealthManager.shared.fetchThisWeekSumQuantity(for: .distanceWalkingRunning, unit: .meterUnit(with: .kilo))
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }

        case .walkDuration:
            break
        case .runDistance:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKSampleType.workoutType()) {
                let summaries = await HealthManager.shared.fetchWorkoutSummariesThisWeek(activityType: .running)
                let totalDistance = summaries.sum(keyPath: \.distance)
                await MainActor.run {
                    self.currentGoalValue = totalDistance
                }
            }
        case .runDuration:
            break
        case .bikeDistance:
            break
        case .bikeDuration:
            break
        case .walkRunBikeDistance:
            break
        case .walkRunBikeDuration:
            break
        case .stepCount:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.stepCount)) {
                let value = await HealthManager.shared.fetchThisWeekSumQuantity(for: .stepCount, unit: .count())
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .meditationMinutes:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKCategoryType(.mindfulSession)) {
                let value = await HealthManager.shared.fetchAverageMeditationMinutesThisWeek()
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
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
        case .increaseProtein:
            try? HealthManager.shared.healthStore.observeChanges(
                sampleTypes: [
                    HKQuantityType(.dietaryProtein),
                    HKQuantityType(.dietaryEnergyConsumed)
                ]
            ) {
                let value = await HealthManager.shared.fetchDietaryNutritionPercentageThisWeek(
                    quantityTypeID: .dietaryProtein,
                    caloriesPerGram: .caloriesPerGramOfProtein
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseCarbs:
            try? HealthManager.shared.healthStore.observeChanges(
                sampleTypes: [
                    HKQuantityType(.dietaryCarbohydrates),
                    HKQuantityType(.dietaryEnergyConsumed)
                ]
            ) {
                let value = await HealthManager.shared.fetchDietaryNutritionPercentageThisWeek(
                    quantityTypeID: .dietaryCarbohydrates,
                    caloriesPerGram: .caloriesPerGramOfCarbs
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseFat:
            try? HealthManager.shared.healthStore.observeChanges(
                sampleTypes: [
                    HKQuantityType(.dietaryFatTotal),
                    HKQuantityType(.dietaryEnergyConsumed)
                ]
            ) {
                let value = await HealthManager.shared.fetchDietaryNutritionPercentageThisWeek(
                    quantityTypeID: .dietaryFatTotal,
                    caloriesPerGram: .caloriesPerGramOfFat
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminA:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.dietaryVitaminA)) {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminA,
                    unit: .gramUnit(with: .micro)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminB6:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.dietaryVitaminB6)) {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminB6,
                    unit: .gramUnit(with: .milli)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminB12:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.dietaryVitaminB12)) {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminB12,
                    unit: .gramUnit(with: .micro)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminC:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.dietaryVitaminC)) {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminC,
                    unit: .gramUnit(with: .milli)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminD:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.dietaryVitaminD)) {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminD,
                    unit: .gramUnit(with: .micro)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminE:
            try? HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.dietaryVitaminE)) {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminE,
                    unit: .gramUnit(with: .milli)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
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
                dueDate: Date().addingTimeInterval(215453),
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
