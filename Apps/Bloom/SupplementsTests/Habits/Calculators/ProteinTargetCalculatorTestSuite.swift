//
//  ProteinTargetCalculatorTestSuite.swift
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
struct ProteinTargetCalculatorTestSuite {

    init() {
        ContainerHolder.shared.setupForTests()
    }

    @Test(arguments: [
        (30, 2000, 140, 1900, HealthGoal.loseWeight, WeightLossSpeed.slow),
        (120, 2000, 140, 1900, HealthGoal.loseWeight, WeightLossSpeed.slow),
        (40, 2000, 140, 1900, HealthGoal.loseWeight, WeightLossSpeed.moderate),
        (100, 2000, 140, 1900, HealthGoal.loseWeight, WeightLossSpeed.fast)
    ])
    func noExistingHabit(
        inputProtein: Double,
        inputDietaryEnergy: Double,
        expectedProtein: Double,
        calorieGoal: Double,
        healthGoal: HealthGoal,
        speed: WeightLossSpeed
    ) async throws {
        let calculator = ProteinTargetCalculator(
            calorieGoal: HKQuantity(unit: .largeCalorie(), doubleValue: calorieGoal),
            targetDetails: .init(
                targetWeight: 160,
                goal: healthGoal,
                weightLossSpeed: speed
            )
        )
        
        let result = try #require(
            await calculator.targetProtein(existingHabit: nil)
        )
        
        let resultValue = result.target.doubleValue(for: .gram())
        
        #expect(resultValue.isWithinRange(of: expectedProtein, precision: 0.01))
    }

    @Test(arguments: [
        (30, 2000, 140, 1900, HealthGoal.loseWeight, WeightLossSpeed.slow),
        (120, 2000, 140, 1900, HealthGoal.loseWeight, WeightLossSpeed.slow),
        (40, 2000, 140, 1900, HealthGoal.loseWeight, WeightLossSpeed.moderate),
        (100, 2000, 140, 1900, HealthGoal.loseWeight, WeightLossSpeed.fast)
    ])
    func existingHabit(
        inputProtein: Double,
        inputDietaryEnergy: Double,
        expectedProtein: Double,
        calorieGoal: Double,
        healthGoal: HealthGoal,
        speed: WeightLossSpeed
    ) async throws {
        let existingHabit = try addHabit()
        
        let calculator = ProteinTargetCalculator(
            calorieGoal: HKQuantity(unit: .largeCalorie(), doubleValue: calorieGoal),
            targetDetails: .init(
                targetWeight: 160,
                goal: healthGoal,
                weightLossSpeed: speed
            )
        )
        
        let result = try #require(
            await calculator.targetProtein(existingHabit: existingHabit)
        )
        
        let resultValue = result.target.doubleValue(for: .gram())
        
        #expect(resultValue.isWithinRange(of: expectedProtein, precision: 0.01))
    }
}

private extension ProteinTargetCalculatorTestSuite {

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
