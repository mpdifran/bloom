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

final actor HabitsFactory {
    static let shared = HabitsFactory()

    private init() { }
}

extension HabitsFactory {

    func generateProposedHabits() async -> NewHabitResult {
        let modelActor = HabitModelActor.standard()
        let activeHabits = (try? await modelActor.fetchActiveHabits()) ?? []

        await VitalsCalculator.shared.forceFetchVitals()

        var newHabitResult = NewHabitResult()

        // Nutrition
        if let nutritionHabits = await generateNutritionHabits(
            activeHabits: activeHabits
        ) {
            newHabitResult.appendNewTargets(result: nutritionHabits)
        }

        // Update existing habits
        for habit in activeHabits.filter(\.isSuggested) {
            guard
                !newHabitResult.contains(habit.targetMetric),
                let newHabit = await updatedHabit(for: habit)
            else { continue }

            // TODO: We may promote this to a habit eventually.
            newHabitResult.proposedFocusAreas.append(newHabit)
        }

        // Add new habits
        if newHabitResult.proposedFocusAreas.count < 2 && newHabitResult.proposedToDos.count == 0 {
            let vitals = await VitalsCalculator.shared.vitals

            for vital in vitals {
                if let newHabit = await suggestNewHabit(for: vital) {
                    newHabitResult.proposedFocusAreas.append(newHabit)
                    break
                }
            }
        }

        return newHabitResult
    }

    func generateProposedHabit(
        for targetMetric: TargetMetric,
        vitalKind: VitalModel.Kind?
    ) async -> ProposedHabit {
        await createHabit(
            targetMetric: targetMetric,
            unit: targetMetric.defaultUnit,
            vitalKind: vitalKind,
            context: nil
        )
    }
}

// MARK: - Nutrition Habits

private extension HabitsFactory {

    func generateNutritionHabits(activeHabits: [HabitDTO]) async -> NewHabitResult? {
        var todos = [ProposedToDo]()
        // Ensure the user has logged their weight
        if await VitalsCalculator.shared.bodyCompositionSummary?.details.averageBodyMass == nil {
            let todo = ProposedToDo(
                todoKind: .logWeight,
                todoCadence: .daily,
                context: "Bloom needs more data before it can suggest a focus area. Please log your weight."
            )
            todos.append(todo)
        }

        // Ensure we have enough food logged
        if await VitalsCalculator.shared.nutritionSummary?.details.hasSufficientNutritionLogs == false {
            let todo = ProposedToDo(
                todoKind: .logFood,
                todoCadence: .daily,
                context: "Bloom needs more data before it can suggest a focus area. Please log your food for at least 7 days."
            )
            todos.append(todo)
            return NewHabitResult(
                proposedFocusAreas: [],
                proposedHabits: [],
                proposedToDos: [todo]
            )
        } else if await VitalsCalculator.shared.nutritionSummary?.details.hasSufficientProteinLogs == false {
            let todo = ProposedToDo(
                todoKind: .logProtein,
                todoCadence: .daily,
                context: "Bloom needs more data before it can suggest a focus area. Please ensure you're logging protein for at least 7 days."
            )
            todos.append(todo)
        }

        if todos.isNotEmpty {
            return NewHabitResult(
                proposedToDos: todos
            )
        }

        guard
            let bodyMass = await VitalsCalculator.shared.bodyCompositionSummary?.details.averageBodyMass,
            let averageDietaryEnergy = await VitalsCalculator.shared.nutritionSummary?.details.dietaryEnergy
        else {
            print("We should never get here.")
            return nil
        }

        if await HealthManager.shared.hasMetWeightGoal(for: bodyMass) {
            var proposedHabits = [ProposedHabit]()
            if let habit = activeHabits.first(where: { $0.targetMetric == .calories }) {
                let calorieHabit = ProposedHabit(
                    habitID: habit.id,
                    targetMetric: .calories,
                    value: habit.value,
                    suggestedValue: habit.value,
                    previousValue: nil,
                    unitString: HKUnit.largeCalorie().unitString,
                    vitalKind: .nutrition,
                    context: "You've met your target weight! Let's make this a permanent habit.",
                    hasUserEdited: habit.isUserEdited
                )
                proposedHabits.append(calorieHabit)
            }
            if let habit = activeHabits.first(where: { $0.targetMetric == .proteinIntake }) {
                let proteinHabit = ProposedHabit(
                    habitID: habit.id,
                    targetMetric: .proteinIntake,
                    value: habit.value,
                    suggestedValue: habit.value,
                    previousValue: nil,
                    unitString: HKUnit.gram().unitString,
                    vitalKind: .nutrition,
                    context: "You've met your target weight! Let's make this a permanent habit.",
                    hasUserEdited: habit.isUserEdited
                )
                proposedHabits.append(proteinHabit)
            }

            return NewHabitResult(
                proposedHabits: proposedHabits
            )
        }

        var newFocusAreas = [ProposedHabit]()

        // Calories
        let basalEnergy = await VitalsCalculator.shared.nutritionSummary?.details.basalEnergyBurned
        let activeEnergy = await VitalsCalculator.shared.nutritionSummary?.details.activeEnergyBurned
        let userReportedActivityLevel = await HealthManager.shared.userReportedActivityLevel
        let activityLevel = await VitalsCalculator.shared.activityLevelSummary?.details.activityLevel ?? userReportedActivityLevel

        let existingCalorieHabit = activeHabits.first(where: { $0.targetMetric == .calories })

        if let recommendation = await CalorieTargetCalculator.targetCalories(
            existingHabit: existingCalorieHabit,
            basalEnergy: basalEnergy,
            activeEnergy: activeEnergy,
            dietaryEnergy: averageDietaryEnergy,
            bodyMass: bodyMass,
            activityLevel: activityLevel,
            targetDetails: HealthManager.shared.healthTargetDetails
        ) {
            let suggestedValue = recommendation.target.doubleValue(for: .largeCalorie())
            let value: Double
            if let existingCalorieHabit, existingCalorieHabit.isUserEdited == true {
                value = existingCalorieHabit.value
            } else {
                value = suggestedValue
            }

            let calorieHabit = ProposedHabit(
                habitID: existingCalorieHabit?.id,
                targetMetric: .calories,
                value: value,
                suggestedValue: suggestedValue,
                previousValue: existingCalorieHabit?.value,
                unitString: HKUnit.largeCalorie().unitString,
                vitalKind: .nutrition,
                context: recommendation.context,
                hasUserEdited: existingCalorieHabit?.isUserEdited == true
            )
            newFocusAreas.append(calorieHabit)
        }

        // Protein
        let existingProteinHabit = activeHabits.first(where: { $0.targetMetric == .proteinIntake })
        if
            let averageProtein = await VitalsCalculator.shared.nutritionSummary?.details.averageProtein,
            let recommendation = await ProteinTargetCalculator.targetProtein(
                existingHabit: existingProteinHabit,
                protein: averageProtein,
                dietaryEnergy: averageDietaryEnergy,
                targetDetails: HealthManager.shared.healthTargetDetails
            )
        {
            let suggestedValue = recommendation.target.doubleValue(for: .gram())
            let value: Double
            if let existingProteinHabit, existingProteinHabit.isUserEdited == true {
                value = existingProteinHabit.value
            } else {
                value = suggestedValue
            }

            let proteinHabit = ProposedHabit(
                habitID: existingProteinHabit?.id,
                targetMetric: .proteinIntake,
                value: value,
                suggestedValue: suggestedValue,
                previousValue: existingProteinHabit?.value,
                unitString: HKUnit.gram().unitString,
                vitalKind: .nutrition,
                context: recommendation.context,
                hasUserEdited: existingProteinHabit?.isUserEdited == true
            )
            newFocusAreas.append(proteinHabit)
        }

        if newFocusAreas.isNotEmpty {
            return NewHabitResult(
                proposedFocusAreas: newFocusAreas,
                proposedHabits: [],
                proposedToDos: []
            )
        }
        return nil
    }
}

private extension HabitsFactory {

    func updatedHabit(for habit: HabitDTO) async -> ProposedHabit? {

        // Cardio Fitness is now Heart Health
        guard habit.vitalKind != .cardioFitness else { return nil }

        // TODO: Determine when to promote to Habit from Focus Area
        guard let recommendation = await GenericHabitTargetCalculator.calculateNewTarget(
            habit: habit
        ) else {
            return nil
        }

        let suggestedValue = recommendation.target.doubleValue(for: habit.unit)
        let value: Double
        if habit.isUserEdited {
            value = habit.value
        } else {
            value = suggestedValue
        }

        return ProposedHabit(
            habitID: habit.id,
            targetMetric: habit.targetMetric,
            value: value,
            suggestedValue: suggestedValue,
            previousValue: habit.value,
            unitString: habit.unitString,
            vitalKind: habit.vitalKind,
            context: recommendation.context,
            hasUserEdited: habit.isUserEdited
        )
    }

    func suggestNewHabit(for vital: VitalModel) async -> ProposedHabit? {
        switch vital.id {
        case .heartHealth:
            return await createHabit(
                targetMetric: .walkingRunningDistance,
                unit: .meterUnit(with: .kilo),
                vitalKind: vital.id,
                context: "Walking or running more can help improve your heart health."
            )
        case .sleepQuality:
            return nil
        case .activityLevel:
            return await createHabit(
                targetMetric: .stepCount,
                unit: .count(),
                vitalKind: vital.id,
                context: "Getting your steps in is an easy way to increase your activity level."
            )
        case .stressLevels:
            return await createHabit(
                targetMetric: .meditationMinutes,
                unit: .minute(),
                vitalKind: vital.id,
                context: "Meditation is a great way to lower stress levels."
            )
        case .exerciseEffectiveness:
            return await createHabit(
                targetMetric: .runDistance,
                unit: .meterUnit(with: .kilo),
                vitalKind: vital.id,
                context: "Running is a great way to spend time in different target heart rate zones."
            )
        case .bowelMovements:
            return await createHabit(
                targetMetric: .waterIntake,
                unit: .literUnit(with: .milli),
                vitalKind: vital.id,
                context: "Staying hydrated can help make your bowel movements more regular."
            )
        case .bodyComposition, .cycleTracking, .nutrition, .cardioFitness:
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
        context: String?
    ) async -> ProposedHabit {
        let average = await targetMetric.fetchDailyAverage(unit: unit, dateRange: .trailingWeeksFromNow(3)).doubleValue(for: unit)

        let min = targetMetric.minHabitTarget.doubleValue(for: unit)
        let value = max(min, average)

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
