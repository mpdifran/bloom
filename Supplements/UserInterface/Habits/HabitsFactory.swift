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

actor HabitsFactory {
    static let shared = HabitsFactory()

    private init() { }
}

extension HabitsFactory {

    func generateProposedHabits() async -> NewHabitResult {
        let modelContext = ContainerHolder.shared.createContext()

        let activeHabits = (try? modelContext.fetchActiveHabits()) ?? []

        await VitalsViewModel.shared.forceFetchVitals()

        if let nutritionHabits = await generateNutritionHabits(
            activeHabits: activeHabits
        ) {
            return nutritionHabits
        }

        var newHabits = [ProposedHabit]()
        for habit in activeHabits.filter(\.isSuggested) {
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
        let userAddedHabits = activeHabits.filter({ $0.isSuggested == false })
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

    func generateNutritionHabits(activeHabits: [Habit]) async -> NewHabitResult? {
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
            let averageDietaryEnergy = VitalsViewModel.shared.nutritionSummary?.details.dietaryEnergy
        else {
            print("We should never get here.")
            return nil
        }

        if HealthManager.shared.hasMetWeightGoal(for: bodyMass) {
            // Suggest them as habits over focus areas?
            return nil
        }

        var habits = [ProposedHabit]()

        // Calories
        let basalEnergy = VitalsViewModel.shared.nutritionSummary?.details.basalEnergyBurned
        let activeEnergy = VitalsViewModel.shared.nutritionSummary?.details.activeEnergyBurned
        let activityLevel = VitalsViewModel.shared.activityLevelSummary?.details.activityLevel // TODO: Use user specified activity level.

        let existingCalorieHabit = activeHabits.first(where: { $0.targetMetric == .calories })

        if let recommendation = await CalorieTargetCalculator.targetCalories(
            existingHabit: existingCalorieHabit?.asDTO(),
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
                habitID: existingCalorieHabit?.persistentModelID,
                targetMetric: .calories,
                value: value,
                suggestedValue: suggestedValue,
                previousValue: existingCalorieHabit?.value,
                unitString: HKUnit.largeCalorie().unitString,
                vitalKind: .nutrition,
                context: recommendation.context,
                hasUserEdited: existingCalorieHabit?.isUserEdited == true
            )
            habits.append(calorieHabit)
        }

        // Protein
        let existingProteinHabit = activeHabits.first(where: { $0.targetMetric == .proteinIntake })
        if
            let averageProtein = VitalsViewModel.shared.nutritionSummary?.details.averageProtein,
            let recommendation = await ProteinTargetCalculator.targetProtein(
                existingHabit: existingProteinHabit?.asDTO(),
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
                habitID: existingProteinHabit?.persistentModelID,
                targetMetric: .proteinIntake,
                value: value,
                suggestedValue: suggestedValue,
                previousValue: existingProteinHabit?.value,
                unitString: HKUnit.gram().unitString,
                vitalKind: .nutrition,
                context: recommendation.context,
                hasUserEdited: existingProteinHabit?.isUserEdited == true
            )
            habits.append(proteinHabit)
        }

        if habits.isNotEmpty {
            return NewHabitResult(
                proposedHabits: habits,
                proposedToDos: []
            )
        }
        return nil
    }
}

private extension HabitsFactory {

    func updatedHabit(for habit: Habit) async -> ProposedHabit? {

        guard let recommendation = await GenericHabitTargetCalculator.calculateNewTarget(
            habit:habit.asDTO()
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
