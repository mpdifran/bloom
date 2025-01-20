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
@testable import Bloom

@Suite(.tags(.targetCalculator))
struct CalorieTargetCalculatorTestSuite {

    init() {
        ContainerHolder.shared.setupForTests()
    }

    @Test(arguments: noExistingHabitsArguments)
    func noExistingHabit(
        input: Input,
        expectedOutput: Double
    ) async throws {
        let calculator = CalorieTargetCalculator(
            age: input.age,
            sex: input.sex,
            bodyMass: HKQuantity(unit: .pound(), doubleValue: input.bodyMass),
            height: HKQuantity(unit: .meterUnit(with: .centi), doubleValue: input.height),
            activityLevel: input.activityLevel,
            targetDetails: .init(
                targetWeight: input.targetWeight,
                goal: input.healthGoal,
                weightLossSpeed: input.speed
            )
        )
        
        let result = try #require(
            await calculator.targetCalories(existingHabit: input.existingHabit)
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
        let height: Double
        let age: Int
        let sex: HKBiologicalSex
        let targetWeight: Double
        let activityLevel: ActivityLevelSummary.ActivityLevel
        let healthGoal: HealthGoal
        let speed: WeightLossSpeed
        let existingHabit: HabitDTO?

        init(
            _ testDescription: String,
            dietary: Double,
            bodyMass: Double,
            height: Double,
            age: Int,
            sex: HKBiologicalSex,
            targetWeight: Double,
            activityLevel: ActivityLevelSummary.ActivityLevel,
            goal: HealthGoal,
            speed: WeightLossSpeed,
            existingHabit: HabitDTO? = nil
        ) {
            self.testDescription = testDescription
            self.dietaryEnergy = dietary
            self.bodyMass = bodyMass
            self.height = height
            self.age = age
            self.sex = sex
            self.targetWeight = targetWeight
            self.activityLevel = activityLevel
            self.healthGoal = goal
            self.speed = speed
            self.existingHabit = existingHabit
        }
    }
}
