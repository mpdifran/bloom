//
//  CalorieTargetCalculatorTestSuite.swift
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
struct CalorieTargetCalculatorTestSuite {

    init() {
        ContainerHolder.shared.setupForTests()
    }

    @Test(arguments: noExistinHabitsArguments)
    func noExistingHabit(
        input: Input,
        expectedOutput: Double
    ) async throws {
        let result = try #require(
            await CalorieTargetCalculator.targetCalories(
                existingHabit: input.existingHabit,
                dietaryEnergy: HKQuantity(unit: .largeCalorie(), doubleValue: input.dietaryEnergy),
                bodyMass: HKQuantity(unit: .pound(), doubleValue: input.bodyMass),
                activityLevel: input.activityLevel,
                targetDetails: .init(
                    targetWeight: input.targetWeight,
                    goal: input.healthGoal,
                    weightLossSpeed: input.speed
                )
            )
        )

        let resultValue = result.target.doubleValue(for: .largeCalorie())

        #expect(resultValue.isWithinRange(of: expectedOutput, precision: 0.01))
    }
}

extension CalorieTargetCalculatorTestSuite {
    struct Input: CustomTestStringConvertible {
        let testDescription: String
        let dietaryEnergy: Double
        let bodyMass: Double
        let targetWeight: Double
        let activityLevel: ActivityLevelSummary.ActivityLevel
        let healthGoal: HealthGoal
        let speed: WeightLossSpeed
        let existingHabit: HabitDTO?

        init(
            _ testDescription: String,
            dietary: Double,
            bodyMass: Double,
            targetWeight: Double,
            activityLevel: ActivityLevelSummary.ActivityLevel,
            goal: HealthGoal,
            speed: WeightLossSpeed,
            existingHabit: HabitDTO? = nil
        ) {
            self.testDescription = testDescription
            self.dietaryEnergy = dietary
            self.bodyMass = bodyMass
            self.targetWeight = targetWeight
            self.activityLevel = activityLevel
            self.healthGoal = goal
            self.speed = speed
            self.existingHabit = existingHabit
        }
    }
}
