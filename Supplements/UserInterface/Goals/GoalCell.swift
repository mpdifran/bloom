//
//  GoalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import HealthKit
import Charts
import AppUI

struct GoalCell: View {
    @Binding var goals: [GoalModel]
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
                    Text(goal.title)
                        .font(.title3)
                        .bold()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Due \(DateFormatter.relativeTimeIntervalDaysFullFromNow(goal.dueDate))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if goals.count > 1 {
                    Menu {
                        Menu("Change Goal", systemImage: "medal") {
                            ForEachEnumerated(goals) { (goalIndex, goal) in
                                Button(goal.title) {
                                    goals.move(fromOffsets: [goalIndex], toOffset: 0)
                                    loadCurrentGoalValue()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                    }
                    .font(.title)
                    .foregroundStyle(goal.metric.measurement.color, .fill)
                }
            }

            barChart

            Text(goal.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

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

    var goal: GoalModel {
        goals.first!
    }

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
            Task {
                let value = await HealthManager.shared.fetchThisWeekSumQuantity(for: .timeInDaylight, unit: .minute())
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }

        case .walkRunDistance:
            Task {
                let value = await HealthManager.shared.fetchThisWeekSumQuantity(for: .distanceWalkingRunning, unit: .meterUnit(with: .kilo))
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }

        case .walkDuration:
            break
        case .runDistance:
            Task {
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
            Task {
                let value = await HealthManager.shared.fetchThisWeekSumQuantity(for: .stepCount, unit: .count())
                await MainActor.run {
                    guard goal.metric.measurement == .stepCount else { return }
                    self.currentGoalValue = value
                }
            }
        case .meditationMinutes:
            Task {
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
            Task {
                let value = await HealthManager.shared.fetchDietaryNutritionPercentageThisWeek(
                    quantityTypeID: .dietaryProtein,
                    caloriesPerGram: .caloriesPerGramOfProtein
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseCarbs:
            Task {
                let value = await HealthManager.shared.fetchDietaryNutritionPercentageThisWeek(
                    quantityTypeID: .dietaryCarbohydrates,
                    caloriesPerGram: .caloriesPerGramOfCarbs
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseFat:
            Task {
                let value = await HealthManager.shared.fetchDietaryNutritionPercentageThisWeek(
                    quantityTypeID: .dietaryFatTotal,
                    caloriesPerGram: .caloriesPerGramOfFat
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminA:
            Task {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminA,
                    unit: .gramUnit(with: .micro)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminB6:
            Task {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminB6,
                    unit: .gramUnit(with: .milli)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminB12:
            Task {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminB12,
                    unit: .gramUnit(with: .micro)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminC:
            Task {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminC,
                    unit: .gramUnit(with: .milli)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminD:
            Task {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminD,
                    unit: .gramUnit(with: .micro)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseVitaminE:
            Task {
                let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                    quantityTypeID: .dietaryVitaminE,
                    unit: .gramUnit(with: .milli)
                )
                await MainActor.run {
                    self.currentGoalValue = value
                }
            }
        case .increaseCalcium, .decreaseCalcium:
            observeNutritionGoalChanges(for: .dietaryCalcium, unit: .gramUnit(with: .milli))
        case .increaseIron, .decreaseIron:
            observeNutritionGoalChanges(for: .dietaryIron, unit: .gramUnit(with: .milli))
        case .increaseMagnesium, .decreaseMagnesium:
            observeNutritionGoalChanges(for: .dietaryMagnesium, unit: .gramUnit(with: .milli))
        case .increasePotassium, .decreasePotassium:
            observeNutritionGoalChanges(for: .dietaryPotassium, unit: .gramUnit(with: .milli))
        case .increaseSodium, .decreaseSodium:
            observeNutritionGoalChanges(for: .dietarySodium, unit: .gramUnit(with: .milli))
        case .increaseZinc, .decreaseZinc:
            observeNutritionGoalChanges(for: .dietaryZinc, unit: .gramUnit(with: .milli))
        case .decreaseSugar:
            observeNutritionGoalChanges(for: .dietarySugar, unit: .gram())
        case .decreaseCaffeine:
            observeNutritionGoalChanges(for: .dietaryCaffeine, unit: .gramUnit(with: .milli))
        case .increaseFiber:
            observeNutritionGoalChanges(for: .dietaryFiber, unit: .gram())
        }
    }

    func observeNutritionGoalChanges(for quantityTypeID: HKQuantityTypeIdentifier, unit: HKUnit) {
        Task {
            let value = await HealthManager.shared.fetchNutritionDailyAverageThisWeek(
                quantityTypeID: quantityTypeID,
                unit: unit
            )
            await MainActor.run {
                self.currentGoalValue = value
            }
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State private var goals: [GoalModel] = [
            GoalModel(
                title: "Get More Sunlight",
                systemImage: "sun.max.fill",
                summary: "More sun is good for your body. It also gives you Vitamin D! Aim to get 50 minutes of sunlight this week.",
                dueDate: Date().addingTimeInterval(215453),
                metric: .init(
                    value: 300,
                    measurement: .timeInDaylight
                ),
                vitalKind: .sleepQuality
            )
        ]

        var body: some View {
            List {
                GoalCell(
                    goals: $goals,
                    index: 0
                )
            }
        }
    }
    return PreviewView()
}
