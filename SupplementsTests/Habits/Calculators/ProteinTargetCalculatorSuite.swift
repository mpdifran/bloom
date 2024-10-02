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

struct ProteinTargetCalculatorSuite {

    init() {
        ContainerHolder.shared.setupForTests()
    }

    struct NoExistingHabit {

        @Test(
            arguments: [
                (30, 2000, 66, HealthGoal.loseWeight, WeightLossSpeed.slow),
                (120, 2000, 129, HealthGoal.loseWeight, WeightLossSpeed.slow),
                (40, 2000, 106, HealthGoal.loseWeight, WeightLossSpeed.moderate),
                (100, 2000, 150, HealthGoal.loseWeight, WeightLossSpeed.fast)
            ]
        )
        func calculateTarget(
            inputProtein: Double,
            inputDietaryEnergy: Double,
            outputProtein: Double,
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

            #expect(resultValue.isWithinRange(of: outputProtein, precision: 0.01))
        }
    }
}
