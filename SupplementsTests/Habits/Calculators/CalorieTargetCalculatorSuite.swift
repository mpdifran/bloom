//
//  CalorieTargetCalculatorSuite.swift
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
struct CalorieTargetCalculatorSuite {

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
                existingHabit: nil,
                basalEnergy: input.basalEnergy.map { HKQuantity(unit: .largeCalorie(), doubleValue: $0) },
                activeEnergy: input.activeEnergy.map { HKQuantity(unit: .largeCalorie(), doubleValue: $0) },
                dietaryEnergy: HKQuantity(unit: .largeCalorie(), doubleValue: input.dietaryEnergy),
                bodyMass: HKQuantity(unit: .pound(), doubleValue: input.bodyMass),
                activityLevel: input.activityLevel,
                targetDetails: .init(
                    goal: input.healthGoal,
                    weightLossSpeed: input.speed
                )
            )
        )

        let resultValue = result.target.doubleValue(for: .largeCalorie())

        #expect(resultValue.isWithinRange(of: expectedOutput, precision: 0.01))
    }
}

extension CalorieTargetCalculatorSuite {
    struct Input: CustomTestStringConvertible {
        let testDescription: String
        let basalEnergy: Double?
        let activeEnergy: Double?
        let dietaryEnergy: Double
        let bodyMass: Double
        let activityLevel: ActivityLevelSummary.ActivityLevel?
        let healthGoal: HealthGoal
        let speed: WeightLossSpeed

        init(
            _ testDescription: String,
            basal: Double?,
            active: Double?,
            dietary: Double,
            bodyMass: Double,
            activityLevel: ActivityLevelSummary.ActivityLevel?,
            goal: HealthGoal,
            speed: WeightLossSpeed
        ) {
            self.testDescription = testDescription
            self.basalEnergy = basal
            self.activeEnergy = active
            self.dietaryEnergy = dietary
            self.bodyMass = bodyMass
            self.activityLevel = activityLevel
            self.healthGoal = goal
            self.speed = speed
        }
    }
}
