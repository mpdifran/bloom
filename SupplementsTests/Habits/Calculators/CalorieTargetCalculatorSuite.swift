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

struct CalorieTargetCalculatorSuite {

    init() {
        ContainerHolder.shared.setupForTests()
    }

    struct NoExistingHabit {

        @Test(
            arguments: [
                (1800, 200, 2000, 1900, HealthGoal.loseWeight, WeightLossSpeed.slow)
            ]
        )
        func calculateTarget(
            basalEnergy: Double,
            activeEnergy: Double,
            dietaryEnergy: Double,
            outputDietaryEnergy: Double,
            healthGoal: HealthGoal,
            speed: WeightLossSpeed
        ) async throws {
            let result = try #require(
                await CalorieTargetCalculator.targetCalories(
                    existingHabit: nil,
                    basalEnergy: HKQuantity(unit: .largeCalorie(), doubleValue: basalEnergy),
                    activeEnergy: HKQuantity(unit: .largeCalorie(), doubleValue: activeEnergy),
                    dietaryEnergy: HKQuantity(unit: .largeCalorie(), doubleValue: dietaryEnergy),
                    targetDetails: .init(
                        goal: healthGoal,
                        weightLossSpeed: speed
                    )
                )
            )

            let resultValue = result.target.doubleValue(for: .largeCalorie())

            #expect(resultValue.isWithinRange(of: outputDietaryEnergy, precision: 0.01))
        }
    }
}
