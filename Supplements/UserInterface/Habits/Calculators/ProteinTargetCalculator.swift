//
//  ProteinTargetCalculator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-01.
//

import Foundation
import HealthKit
import DataContainer

private extension Double {
    static let initialProteinOverallCaloriePercent: Double = 0.30
    static let intermediateProteinOverallCaloriePercent: Double = 0.35
    static let advancedProteinOverallCaloriePercent: Double = 0.40
}

enum ProteinTargetCalculator {

    static func targetProtein(
        existingHabit: HabitDTO?,
        protein: HKQuantity,
        dietaryEnergy: HKQuantity,
        targetDetails: HealthTargetDetails
    ) async -> TargetMetricRecommendation? {

        if let existingHabit {
            return await updateExistingHabit(
                existingHabit: existingHabit,
                protein: protein,
                dietaryEnergy: dietaryEnergy,
                targetDetails: targetDetails
            )
        }

        return createNewProteinGoal(
            protein: protein,
            dietaryEnergy: dietaryEnergy,
            targetDetails: targetDetails
        )
    }
}

private extension ProteinTargetCalculator {

    static func createNewProteinGoal(
        protein: HKQuantity,
        dietaryEnergy: HKQuantity,
        targetDetails: HealthTargetDetails
    ) -> TargetMetricRecommendation? {
        guard let proteinTarget = calculateTargetProtein(
            protein: protein,
            dietaryEnergy: dietaryEnergy,
            targetDetails: targetDetails
        ) else {
            return nil
        }

        let context: String
        switch targetDetails.goal {
        case .loseWeight:
            context = "Eating more protein can help you stay satiated and lose weight sustainably."
        case .gainWeight:
            context = "Eating more protein can help you gain weight sustainably."
        case .maintainWeight, .none:
            return nil
        }

        return TargetMetricRecommendation(
            target: proteinTarget,
            context: context
        )
    }

    static func updateExistingHabit(
        existingHabit: HabitDTO,
        protein: HKQuantity,
        dietaryEnergy: HKQuantity,
        targetDetails: HealthTargetDetails
    ) async -> TargetMetricRecommendation? {

        let habitGoalStatistics = await HabitGoalStatisticsCalculator.calculateStatistics(for: existingHabit)

        let existingHabitTargetValue = existingHabit.value

        if habitGoalStatistics.missedGoalCountPercentage > 0.4 {
            // Decrease protein goal
            let newValue = existingHabitTargetValue * (1 - (habitGoalStatistics.averagePercentMissedGoalBy / 2))

            return TargetMetricRecommendation(
                target: HKQuantity(unit: existingHabit.unit, doubleValue: newValue),
                context: "Looks like you haven't been hitting your protein goal recently. Let's set a more achievable goal."
            )
        } else if habitGoalStatistics.missedGoalSamples.count < 3 {
            // Increase protein percentage
            if let proteinTarget = calculateTargetProtein(
                protein: protein,
                dietaryEnergy: dietaryEnergy,
                targetDetails: targetDetails
            ) {
                return TargetMetricRecommendation(
                    target: proteinTarget,
                    context: "Great job getting your protein! Let's set a new goal to challenge you."
                )
            } else {
                return nil // I guess the goals changed?
            }
        } else {
            // Keep the same
            return TargetMetricRecommendation(
                target: existingHabit.quantity,
                context: "Keep up the good work! We'll keep your goal the same this week."
            )
        }
    }

    static func calculateTargetProtein(
        protein: HKQuantity,
        dietaryEnergy: HKQuantity,
        targetDetails: HealthTargetDetails
    ) -> HKQuantity? {
        let currentProteinPercent = (protein.doubleValue(for: .gram()) * .caloriesPerGramOfProtein) / dietaryEnergy.doubleValue(for: .largeCalorie())

        let percentDifference: Double
        if currentProteinPercent > .advancedProteinOverallCaloriePercent {
            return nil
        } else if currentProteinPercent > .intermediateProteinOverallCaloriePercent {
            percentDifference = Double.advancedProteinOverallCaloriePercent - currentProteinPercent
        } else if currentProteinPercent > .initialProteinOverallCaloriePercent {
            percentDifference = Double.intermediateProteinOverallCaloriePercent - currentProteinPercent
        } else {
            percentDifference = Double.initialProteinOverallCaloriePercent - currentProteinPercent
        }

        let targetProteinPercent: Double
        switch targetDetails.goal {
        case .loseWeight:
            switch targetDetails.weightLossSpeed {
            case .slow:
                targetProteinPercent = currentProteinPercent + percentDifference * 0.3
            case .moderate:
                targetProteinPercent = currentProteinPercent + percentDifference * 0.6
            case .fast:
                targetProteinPercent = currentProteinPercent + percentDifference
            }
        case .gainWeight:
            targetProteinPercent = currentProteinPercent + percentDifference // TODO: Ask Kaitlyn what to do here.
        case .maintainWeight, .none:
            return nil
        }

        let targetProteinCalories = targetProteinPercent * dietaryEnergy.doubleValue(for: .largeCalorie())
        let minProteinTarget = TargetMetric.proteinIntake.minHabitTarget.doubleValue(for: .gram())
        let proteinGrams = max(targetProteinCalories / .caloriesPerGramOfProtein, minProteinTarget)

        return HKQuantity(unit: .gram(), doubleValue: proteinGrams.roundedToNiceNumber())
    }
}
