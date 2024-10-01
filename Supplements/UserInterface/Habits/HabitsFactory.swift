//
//  HabitsFactory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-23.
//

import Foundation
import SwiftData
import DataContainer
import HealthKit
import TelemetryDeck

private extension Double {
    static let initialProteinOverallCaloriePercent: Double = 0.30
    static let intermediateProteinOverallCaloriePercent: Double = 0.35
    static let advancedProteinOverallCaloriePercent: Double = 0.40
}

actor HabitsFactory {
    static let shared = HabitsFactory()

    let modelContext = ModelContext(ContainerHolder.shared.container)

    private init() { }
}

extension HabitsFactory {

    func generateProposedHabits() async -> NewHabitResult {
        let existingHabits = (try? modelContext.fetchActiveHabits(isSuggested: true)) ?? []
        let userAddedHabits = (try? modelContext.fetchActiveHabits(isSuggested: false)) ?? []

        await VitalsViewModel.shared.forceFetchVitals()

        if let nutritionHabits = await generateNutritionHabits(
            existingHabits: existingHabits,
            userAddedHabits: userAddedHabits
        ) {
            return nutritionHabits
        }

        var newHabits = [ProposedHabit]()
        for habit in existingHabits {
            guard let newHabit = await updatedHabit(for: habit) else { continue }

            newHabits.append(newHabit)
        }

        if newHabits.isEmpty {

            let vitals = VitalsViewModel.shared.vitals

            if
                let targetVital = vitals.safeAccess(at: 0),
                let newHabit = await suggestNewHabit(for: targetVital)
            {
                newHabits.append(newHabit)
            }
        }

        // Make sure there's no duplicates
        var targetMetrics: Set<TargetMetric> = userAddedHabits.map(\.targetMetric).asSet()
        newHabits = newHabits.filter({ newHabit in
            let shouldInclude = !targetMetrics.contains(newHabit.targetMetric)
            targetMetrics.insert(newHabit.targetMetric)
            return shouldInclude
        })

        return NewHabitResult(proposedHabits: newHabits, proposedToDos: [])
    }

    func generateProposedHabit(
        for targetMetric: TargetMetric,
        vitalKind: VitalModel.Kind?
    ) async -> ProposedHabit {
        await createHabit(
            targetMetric: targetMetric,
            unit: targetMetric.defaultUnit,
            vitalKind: vitalKind,
            context: ""
        )
    }
}

// MARK: - Nutrition Habits

private extension HabitsFactory {

    func generateNutritionHabits(existingHabits: [Habit], userAddedHabits: [Habit]) async -> NewHabitResult? {
        var todos = [ProposedToDo]()
        // Ensure the user has logged their weight
        if VitalsViewModel.shared.bodyCompositionSummary?.details.averageBodyMass == nil {
            let todo = ProposedToDo(
                todoKind: .logWeight,
                todoCadence: .daily,
                context: "Bloom needs more data before it can suggest a focus area. Please log your weight."
            )
            todos.append(todo)
        }

        // Ensure we have enough food logged
        if VitalsViewModel.shared.nutritionSummary?.details.hasSufficientNutritionLogs == false {
            let todo = ProposedToDo(
                todoKind: .logFood,
                todoCadence: .daily,
                context: "Bloom needs more data before it can suggest a focus area. Please log your food for at least 7 days."
            )
            todos.append(todo)
            return NewHabitResult(
                proposedHabits: [],
                proposedToDos: [todo]
            )
        } else if VitalsViewModel.shared.nutritionSummary?.details.hasSufficientProteinLogs == false {
            let todo = ProposedToDo(
                todoKind: .logProtein,
                todoCadence: .daily,
                context: "Bloom needs more data before it can suggest a focus area. Please ensure you're logging protein for at least 7 days."
            )
            todos.append(todo)
        }

        if todos.isNotEmpty {
            return NewHabitResult(proposedHabits: [], proposedToDos: todos)
        }

        guard
            let bodyMass = VitalsViewModel.shared.bodyCompositionSummary?.details.averageBodyMass,
            let averageDietaryEnergy = VitalsViewModel.shared.nutritionSummary?.details.dietaryEnergy?.doubleValue(for: .largeCalorie())
        else {
            print("We should never get here.")
            return NewHabitResult(proposedHabits: [], proposedToDos: [])
        }

        // Check the user's goal
        if HealthManager.shared.healthGoal == .loseWeight {
            let targetWeight = HealthManager.shared.targetWeight // lbs
            let currentWeight = bodyMass.doubleValue(for: .pound()) // lbs

            let proteinTarget = averageDietaryEnergy * .initialProteinOverallCaloriePercent / .caloriesPerGramOfProtein

            let proteinHabit = ProposedHabit(
                habitID: nil,
                targetMetric: .proteinIntake,
                value: proteinTarget,
                suggestedValue: proteinTarget,
                previousValue: nil,
                unitString: HKUnit.gram().unitString,
                vitalKind: .nutrition,
                context: "Eating more protein can help you stay satiated and lose weight sustainably.",
                hasUserEdited: false
            )

            return NewHabitResult(
                proposedHabits: [proteinHabit],
                proposedToDos: []
            )
        }

        return nil
    }
}

private extension HabitsFactory {

    func updatedHabit(for habit: Habit) async -> ProposedHabit? {
        let targetMetric = habit.targetMetric
        let unit = habit.unit

        let habitHistory: [Habit]
        do {
            habitHistory = try modelContext.fetchHabits(for: targetMetric, isSuggested: true)
        } catch {
            print(error)
            TelemetryDeck.errorOccurred(
                id: "HabitsViewModel.fetchSuggestedHabits",
                category: .thrownException,
                message: error.localizedDescription
            )
            habitHistory = []
        }

        // Calcualte changes to new habit target.
        let habitTargetValue = habit.quantity.doubleValue(for: unit)

        let lastTwoWeeksSamples = await targetMetric.fetchCollatedDailyQuantity(
            unit: unit,
            dateRange: .trailingWeeksFromNow(2)
        )

        let habitGoalStatistics = calculateHabitGoalStatistics(habitHistory: habitHistory, samples: lastTwoWeeksSamples)

        var newHabitTargetValue: Double
        if habitGoalStatistics.missedGoalCountPercentage > 0.4 {
            // decrease target
            let averagePercentMissedGoalBy = habitGoalStatistics.averagePercentMissedGoalBy
            newHabitTargetValue = habitTargetValue * (1 - (averagePercentMissedGoalBy / 2))
        } else if habitGoalStatistics.missedGoalSamples.count < 3 {
            // increase target
            let averagePercentExceededGoalBy = habitGoalStatistics.averagePercentExceededGoalBy
            newHabitTargetValue = habitTargetValue * (1 + (averagePercentExceededGoalBy / 2))
        } else {
            // keep target the same
            newHabitTargetValue = habitTargetValue
        }

        // Check the ideal range
        if let idealRange = targetMetric.idealRange {
            let targetQuantity = HKQuantity(unit: unit, doubleValue: newHabitTargetValue)

            if idealRange.upper.compare(targetQuantity) == .orderedAscending {
                newHabitTargetValue = idealRange.upperDoubleValue(for: unit)
            }
        }

        let previousValue = habitHistory.last?.quantity.doubleValue(for: unit)

        if habit.isUserEdited {
            return ProposedHabit(
                habitID: habit.id,
                targetMetric: targetMetric,
                value: habitTargetValue,
                suggestedValue: newHabitTargetValue,
                previousValue: nil,
                unitString: unit.unitString,
                vitalKind: habit.vitalKind,
                context: habit.context,
                hasUserEdited: true
            )
        } else {
            return ProposedHabit(
                habitID: habit.id,
                targetMetric: targetMetric,
                value: newHabitTargetValue,
                suggestedValue: newHabitTargetValue,
                previousValue: previousValue,
                unitString: unit.unitString,
                vitalKind: habit.vitalKind,
                context: habit.context,
                hasUserEdited: false
            )
        }
    }

    func calculateHabitGoalStatistics(
        habitHistory: [Habit],
        samples: [DateQuantitySample]
    ) -> HabitGoalStatistics {

        var metGoalSamples = [HabitGoalStatistics.HabitSamplePair]()
        var missedGoalSamples = [HabitGoalStatistics.HabitSamplePair]()

        for sample in samples {
            let habit: Habit

            if let timelineHabit = habitHistory.first(where: { $0.isDateWithinHabit(date: sample.date) }) {
                habit = timelineHabit
            } else if let oldestHabit = habitHistory.min(by: \.startDate) {
                habit = oldestHabit
            } else {
                continue
            }

            let unit = habit.unit
            let habitTarget = habit.quantity.doubleValue(for: unit)
            let sampleValue = sample.quantity.doubleValue(for: unit)

            if sampleValue >= (habitTarget * 0.95) { // 5% for grace around meeting goals
                metGoalSamples.append(
                    .init(habit: habit, sample: sample)
                )
            } else {
                missedGoalSamples.append(
                    .init(habit: habit, sample: sample)
                )
            }
        }

        return HabitGoalStatistics(
            metGoalSamples: metGoalSamples,
            missedGoalSamples: missedGoalSamples
        )
    }

    func suggestNewHabit(for vital: VitalModel) async -> ProposedHabit? {
        switch vital.id {
        case .heartHealth:
            return await createHabit(
                targetMetric: .walkingRunningDistance,
                unit: .meterUnit(with: .kilo),
                vitalKind: vital.id,
                context: ""
            )
        case .sleepQuality:
            // Maintain weight
            return await createHabit(
                targetMetric: .timeInDaylight,
                unit: .minute(),
                vitalKind: vital.id,
                context: ""
            )
        case .activityLevel:
            return await createHabit(
                targetMetric: .stepCount,
                unit: .count(),
                vitalKind: vital.id,
                context: ""
            )
        case .stressLevels:
            // Maintain weight
            return await createHabit(
                targetMetric: .timeInDaylight,
                unit: .minute(),
                vitalKind: vital.id,
                context: ""
            )
        case .nutrition:
            // Lose weight + gain weight
            // Calorie intake / net energy
            // Options: Calories, cal + protein, macros
            // 1200 calories is not recommended
            // Suggest a weight loss plan
            // TODO: should be protein and calorie goal. Calorie goal should have 10% variance to count as complete.
            return await createHabit(
                targetMetric: .waterIntake,
                unit: .literUnit(with: .milli),
                vitalKind: vital.id,
                context: ""
            )
        case .exerciseEffectiveness:
            return await createHabit(
                targetMetric: .walkingRunningDistance,
                unit: .meterUnit(with: .kilo),
                vitalKind: vital.id,
                context: ""
            )
        case .bowelMovements:
            return await createHabit(
                targetMetric: .waterIntake,
                unit: .literUnit(with: .milli),
                vitalKind: vital.id,
                context: ""
            )
        case .bodyComposition, .cycleTracking:
            return nil
        @unknown default:
            fatalError("Unknown VitalModel.Kind case")
        }
    }
}

private extension HabitsFactory {

    func createHabit(
        targetMetric: TargetMetric,
        unit: HKUnit,
        vitalKind: VitalModel.Kind?,
        context: String
    ) async -> ProposedHabit {
        let average = await targetMetric.fetchDailyAverage(unit: unit, dateRange: .trailingWeeksFromNow(3)).doubleValue(for: unit)
        let value: Double
        if let min = targetMetric.minHabitTarget?.doubleValue(for: unit) {
            value = max(min, average)
        } else {
            value = average
        }
        return ProposedHabit(
            habitID: nil,
            targetMetric: targetMetric,
            value: value,
            suggestedValue: value,
            previousValue: nil,
            unitString: unit.unitString,
            vitalKind: vitalKind,
            context: context,
            hasUserEdited: false
        )
    }
}
