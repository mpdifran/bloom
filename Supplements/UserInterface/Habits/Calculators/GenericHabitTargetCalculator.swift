//
//  GenericHabitTargetCalculator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-02.
//

import Foundation
import HealthKit
import DataContainer
import TelemetryDeck

enum GenericHabitTargetCalculator {

    static func calculateNewTarget(habit: HabitDTO) async -> TargetMetricRecommendation? {
        let targetMetric = habit.targetMetric
        let unit = habit.unit
        let habitTargetValue = habit.quantity.doubleValue(for: unit)

        let habitGoalStatistics = await HabitGoalStatisticsCalculator.calculateStatistics(for: habit)

        return habitGoalStatistics.newHabitGoal(for: habit)
    }
}
