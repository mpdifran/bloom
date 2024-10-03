//
//  ProteinTargetCalculatorSuite.swift
//  SupplementsTests
//
//  Created by Mark DiFranco on 2024-10-02.
//

import Testing
import HealthKit
import DataContainer
import BloomFoundation
@testable import Supplements

@Suite(.tags(.targetCalculator))
struct ProteinTargetCalculatorSuite {

    init() {
        ContainerHolder.shared.setupForTests()
    }

    @Test(
        arguments: [
            (30, 2000, 66, HealthGoal.loseWeight, WeightLossSpeed.slow),
            (120, 2000, 129, HealthGoal.loseWeight, WeightLossSpeed.slow),
            (40, 2000, 106, HealthGoal.loseWeight, WeightLossSpeed.moderate),
            (100, 2000, 150, HealthGoal.loseWeight, WeightLossSpeed.fast)
        ]
    )
    func noExistingHabit(
        inputProtein: Double,
        inputDietaryEnergy: Double,
        expectedProtein: Double,
        healthGoal: HealthGoal,
        speed: WeightLossSpeed
    ) async throws {
        let result = try #require(
            await ProteinTargetCalculator.targetProtein(
                existingHabit: nil,
                protein: HKQuantity(unit: .gram(), doubleValue: inputProtein),
                dietaryEnergy: HKQuantity(unit: .largeCalorie(), doubleValue: inputDietaryEnergy),
                targetDetails: .init(
                    goal: healthGoal,
                    weightLossSpeed: speed
                )
            )
        )

        let resultValue = result.target.doubleValue(for: .gram())

        #expect(resultValue.isWithinRange(of: expectedProtein, precision: 0.01))
    }

    @Test(
        .disabled("Need to remove shared singleton."),
        arguments: [
            (30, 2000, 40.6, HealthGoal.loseWeight, WeightLossSpeed.slow),
            (120, 2000, 40.6, HealthGoal.loseWeight, WeightLossSpeed.slow),
            (40, 2000, 40.6, HealthGoal.loseWeight, WeightLossSpeed.moderate),
            (100, 2000, 40.6, HealthGoal.loseWeight, WeightLossSpeed.fast)
        ]
    )
    func lowTargetExistingHabit(
        inputProtein: Double,
        inputDietaryEnergy: Double,
        expectedProtein: Double,
        healthGoal: HealthGoal,
        speed: WeightLossSpeed
    ) async throws {
        let existingHabit = try addHabit()

        let result = try #require(
            await ProteinTargetCalculator.targetProtein(
                existingHabit: existingHabit,
                protein: HKQuantity(unit: .gram(), doubleValue: inputProtein),
                dietaryEnergy: HKQuantity(unit: .largeCalorie(), doubleValue: inputDietaryEnergy),
                targetDetails: .init(
                    goal: healthGoal,
                    weightLossSpeed: speed
                )
            )
        )

        let resultValue = result.target.doubleValue(for: .gram())

        #expect(resultValue.isWithinRange(of: expectedProtein, precision: 0.01))
    }
}

private extension ProteinTargetCalculatorSuite {

    func addHabit() throws -> HabitDTO {
        let startDate = try #require(Calendar.current.date(byAdding: .day, value: -7, to: .now))

        let habit = Habit(
            targetMetric: .proteinIntake,
            value: 60,
            unitString: HKUnit.gram().unitString,
            startDate: startDate,
            isSuggested: true,
            isUserEdited: false
        )

        let context = ContainerHolder.shared.createContext()
        context.insert(habit)

        try context.save()

        return habit.asDTO()
    }
}
