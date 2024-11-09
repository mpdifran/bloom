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
}

enum CalorieTargetCalculator {

    static func targetCalories(
        existingHabit: HabitDTO?,
        dietaryEnergy: HKQuantity,
        bodyMass: HKQuantity,
        activityLevel: ActivityLevelSummary.ActivityLevel,
        targetDetails: HealthTargetDetails
    ) async -> TargetMetricRecommendation? {

        if let existingHabit {
            return await updateExistingHabit(
                existingHabit: existingHabit,
                dietaryEnergy: dietaryEnergy,
                bodyMass: bodyMass,
                activityLevel: activityLevel,
                targetDetails: targetDetails
            )
        } else {
            return createNewCalorieGoal(
                dietaryEnergy: dietaryEnergy,
                bodyMass: bodyMass,
                activityLevel: activityLevel,
                targetDetails: targetDetails
            )
        }
    }
}

private extension CalorieTargetCalculator {

    static func createNewCalorieGoal(
        dietaryEnergy: HKQuantity,
        bodyMass: HKQuantity,
        activityLevel: ActivityLevelSummary.ActivityLevel,
        targetDetails: HealthTargetDetails
    ) -> TargetMetricRecommendation? {

        if
            let calorieMultiplier = activityLevel.calorieMultiplier(for: targetDetails)
        {
            let targetCalories = calorieMultiplier * bodyMass.doubleValue(for: .pound())
            return calculateActivityLevelBasedCalorieGoal(targetCalories: targetCalories, targetDetails: targetDetails)
        } else {
            let dietaryEnergy = dietaryEnergy.doubleValue(for: .largeCalorie())
            return calculateEnergyBasedCalorieGoal(currentEnergy: dietaryEnergy, targetDetails: targetDetails)
        }
    }

    static func calculateEnergyBasedCalorieGoal(
        currentEnergy: Double,
        targetDetails: HealthTargetDetails
    ) -> TargetMetricRecommendation? {
        let targetCalories: Double
        let context: String
        switch targetDetails.goal {
        case .loseWeight:
            switch targetDetails.weightLossSpeed {
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

        let minCalorieTarget = TargetMetric.calories.minHabitTarget.doubleValue(for: .largeCalorie())
        let cappedTargetCalories = max(targetCalories, minCalorieTarget) // Ensure we never go too low

        return TargetMetricRecommendation(
            target: HKQuantity(unit: .largeCalorie(), doubleValue: cappedTargetCalories.roundedToNiceNumber()),
            context: context
        )
    }

    static func calculateActivityLevelBasedCalorieGoal(
        targetCalories: Double,
        targetDetails: HealthTargetDetails
    ) -> TargetMetricRecommendation? {

        let context: String
        switch targetDetails.goal {
        case .loseWeight:
            context = "Maintaining a calorie deficit is an important part of losing weight."
        case .maintainWeight:
            context = "Try and maintain the same calorie intake to maintain your current weight."
        case .gainWeight:
            context = "Maintaining a calorie surplus is an important part of gaining weight."
        case .none:
            return nil
        }

        let minCalorieTarget = TargetMetric.calories.minHabitTarget.doubleValue(for: .largeCalorie())
        let cappedTargetCalories = max(targetCalories, minCalorieTarget) // Ensure we never go too low

        return TargetMetricRecommendation(
            target: HKQuantity(unit: .largeCalorie(), doubleValue: cappedTargetCalories.roundedToNiceNumber()),
            context: context
        )
    }
}

private extension CalorieTargetCalculator {

    static func updateExistingHabit(
        existingHabit: HabitDTO,
        dietaryEnergy: HKQuantity,
        bodyMass: HKQuantity,
        activityLevel: ActivityLevelSummary.ActivityLevel,
        targetDetails: HealthTargetDetails
    ) async -> TargetMetricRecommendation? {

        if
            let calorieMultiplier = activityLevel.calorieMultiplier(for: targetDetails)
        {

            let targetCalories = calorieMultiplier * bodyMass.doubleValue(for: .pound())

            if
                let recommendation = calculateActivityLevelBasedCalorieGoal(targetCalories: targetCalories, targetDetails: targetDetails),
                !recommendation.target.doubleValue(for: .largeCalorie()).isWithinRange(of: existingHabit.value, precision: 0.1)
            {
                if
                    targetDetails.goal != .loseWeight ||
                    recommendation.target.doubleValue(for: .largeCalorie()) < existingHabit.value
                {
                    return TargetMetricRecommendation(
                        target: recommendation.target,
                        context: "Your activity level has changed, so we recommend changing your calorie goal to match."
                    )
                }
            }
        }

        // If we're not changing it because of the above, then keep the goal the same.

        let habitGoalStatistics = await HabitGoalStatisticsCalculator.calculateStatistics(for: existingHabit)

        let context: String
        if habitGoalStatistics.missedGoalCountPercentage > 0.4 {
            context = "Looks like you had some trouble hitting this goal last week. Let's turn over a new leaf this week!"
        } else if habitGoalStatistics.missedGoalSamples.count < 3 {
            context = "Great job hitting this goal over the last couple weeks, keep up the good work!"
        } else {
            context = "You're on the right track, keep it up!"
        }

        return TargetMetricRecommendation(
            target: existingHabit.quantity,
            context: context
        )
    }
}
