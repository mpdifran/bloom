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
@testable import Bloom

@Suite(.tags(.targetCalculator))
struct ProteinTargetCalculatorTestSuite {

    init() {
        ContainerHolder.shared.setupForTests()
    }

    @Test(arguments: [
        (143, 1900, HealthGoal.loseWeight, WeightLossSpeed.slow),
        (105, 1400, HealthGoal.loseWeight, WeightLossSpeed.slow),
        (90, 1200, HealthGoal.loseWeight, WeightLossSpeed.moderate),
        (116, 1550, HealthGoal.loseWeight, WeightLossSpeed.fast)
    ])
    func noExistingHabit(
        expectedProtein: Double,
        calorieGoal: Double,
        healthGoal: HealthGoal,
        speed: WeightLossSpeed
    ) async throws {
        let calculator = ProteinTargetCalculator(
            calorieGoal: HKQuantity(unit: .largeCalorie(), doubleValue: calorieGoal),
            targetDetails: HealthTargetDetails(
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
        (140, 1900, HealthGoal.loseWeight, WeightLossSpeed.slow),
        (140, 1900, HealthGoal.loseWeight, WeightLossSpeed.slow),
        (140, 1900, HealthGoal.loseWeight, WeightLossSpeed.moderate),
        (140, 1900, HealthGoal.loseWeight, WeightLossSpeed.fast)
    ])
    func existingHabit(
        expectedProtein: Double,
        calorieGoal: Double,
        healthGoal: HealthGoal,
        speed: WeightLossSpeed
    ) async throws {
        let existingHabit = try addHabit()
        
        let calculator = ProteinTargetCalculator(
            calorieGoal: HKQuantity(unit: .largeCalorie(), doubleValue: calorieGoal),
            targetDetails: HealthTargetDetails(
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
