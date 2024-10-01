//
//  CalorieTargetCalculator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-01.
//

import Foundation
import HealthKit
import DataContainer

private extension Double {
    static let calorieSurplusPercentage: Double = 1.1
    static let calorieDeficitSlowPercentage: Double = 0.95
    static let calorieDeficitModeratePercentage: Double = 0.9
    static let calorieDeficitFastPercentage: Double = 0.85
    static let minCalorieTarget: Double = 1500
}

enum CalorieTargetCalculator {

    static func targetCalories(
        basalEnergy: HKQuantity?,
        activeEnergy: HKQuantity?,
        dietaryEnergy: HKQuantity
    ) -> TargetMetricRecommendation? {

        let currentEnergy: Double
        if let basalEnergy, let activeEnergy {
            let tdee = basalEnergy.doubleValue(for: .largeCalorie()) + activeEnergy.doubleValue(for: .largeCalorie())
            currentEnergy = min(tdee, dietaryEnergy.doubleValue(for: .largeCalorie()))
        } else {
            currentEnergy = dietaryEnergy.doubleValue(for: .largeCalorie())
        }

        let targetCalories: Double
        let context: String
        switch HealthManager.shared.healthGoal {
        case .loseWeight:
            switch HealthManager.shared.weightLossSpeed {
            case .slow:
                targetCalories = currentEnergy * .calorieDeficitSlowPercentage
            case .moderate:
                targetCalories = currentEnergy * .calorieDeficitModeratePercentage
            case .fast:
                targetCalories = currentEnergy * .calorieDeficitFastPercentage
            }
            context = "Maintaining a calorie deficit is an important part of losing weight."
        case .maintainWeight:
            targetCalories = currentEnergy
            context = "Try and maintain the same calorie intake to maintain your current weight."
        case .gainWeight:
            targetCalories = currentEnergy * .calorieSurplusPercentage
            context = "Maintaining a calorie surplus is an important part of gaining weight."
        case .none:
            return nil
        }

        let minCalorieTarget = TargetMetric.calories.minHabitTarget?.doubleValue(for: .largeCalorie()) ?? .minCalorieTarget
        let cappedTargetCalories = max(targetCalories, minCalorieTarget) // Ensure we never go too low

        return TargetMetricRecommendation(
            target: HKQuantity(unit: .largeCalorie(), doubleValue: cappedTargetCalories.roundedToNiceNumber()),
            context: context
        )
    }
}
