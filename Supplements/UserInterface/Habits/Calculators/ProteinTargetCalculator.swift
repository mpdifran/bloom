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

    static func targetProtein(protein: HKQuantity, dietaryEnergy: HKQuantity) -> TargetMetricRecommendation? {

        let currentProteinPercent = (protein.doubleValue(for: .gram()) * .caloriesPerGramOfProtein) / dietaryEnergy.doubleValue(for: .largeCalorie())

        // TODO: Work in some logic to make this more dynamic
        guard currentProteinPercent < .initialProteinOverallCaloriePercent else {
            return nil
        }

        let percentDifference = Double.initialProteinOverallCaloriePercent - currentProteinPercent

        let targetProteinPercent: Double
        let context: String
        switch HealthManager.shared.healthGoal {
        case .loseWeight:
            switch HealthManager.shared.weightLossSpeed {
            case .slow:
                targetProteinPercent = currentProteinPercent + percentDifference * 0.3
            case .moderate:
                targetProteinPercent = currentProteinPercent + percentDifference * 0.6
            case .fast:
                targetProteinPercent = Double.initialProteinOverallCaloriePercent
            }
            context = "Eating more protein can help you stay satiated and lose weight sustainably."
        case .gainWeight:
            targetProteinPercent = Double.initialProteinOverallCaloriePercent // TODO: Ask Kaitlyn what to do here.
            context = "Eating more protein can help you gain weight sustainably."
        case .maintainWeight, .none:
            return nil
        }

        let targetProteinCalories = targetProteinPercent * dietaryEnergy.doubleValue(for: .largeCalorie())
        let minProteinTarget = TargetMetric.proteinIntake.minHabitTarget?.doubleValue(for: .gram()) ?? Double.infinity
        let proteinGrams = max(targetProteinCalories / .caloriesPerGramOfProtein, minProteinTarget)

        return TargetMetricRecommendation(
            target: HKQuantity(unit: .gram(), doubleValue: proteinGrams.roundedToNiceNumber()),
            context: context
        )
    }
}
