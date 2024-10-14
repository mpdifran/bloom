//
//  HabitGoalStatistics.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-21.
//

import DataContainer
import HealthKit

struct HabitGoalStatistics {
    let metGoalSamples: [HabitSamplePair]
    let missedGoalSamples: [HabitSamplePair]
}

extension HabitGoalStatistics {

    var totalSampleCount: Int {
        metGoalSamples.count + missedGoalSamples.count
    }

    var missedGoalCountPercentage: Double {
        Double(missedGoalSamples.count) / Double(totalSampleCount)
    }

    var averagePercentMissedGoalBy: Double {
        missedGoalSamples.average(keyPath: \.belowGoalPercentage)
    }

    var metGoalCountPercentage: Double {
        Double(metGoalSamples.count) / Double(totalSampleCount)
    }

    var averagePercentExceededGoalBy: Double {
        metGoalSamples.average(keyPath: \.exceedingGoalPercentage)
    }
}

extension HabitGoalStatistics {

    func newHabitGoal(for existingHabit: HabitDTO) -> TargetMetricRecommendation {

        if missedGoalCountPercentage > 0.4 {
            // decrease target
            let newValue = existingHabit.value * (1 - (averagePercentMissedGoalBy / 2))

            return TargetMetricRecommendation(
                target: HKQuantity(unit: existingHabit.unit, doubleValue: newValue),
                context: "Looks like you haven't been hitting your goal recently. Let's set a more achievable goal."
            )
        } else if missedGoalSamples.count < 3 {
            if existingHabit.targetMetric.idealRange?.contains(quantity: existingHabit.quantity) == true {
                // TODO: Promote to habit here?
                return TargetMetricRecommendation(
                    target: existingHabit.quantity,
                    context: "Way to continue hitting your goal! We'll keep your goal the same this week."
                )
            }

            // increase target
            let newValue = existingHabit.value * (1 + (averagePercentExceededGoalBy / 2))

            return TargetMetricRecommendation(
                target: HKQuantity(unit: existingHabit.unit, doubleValue: newValue),
                context: "Great job hitting your goal! Let's set a new goal to challenge you."
            )
        } else {
            // keep target the same
            return TargetMetricRecommendation(
                target: existingHabit.quantity,
                context: "Keep up the good work! We'll keep your goal the same this week."
            )
        }
    }
}

extension HabitGoalStatistics {
    struct HabitSamplePair {
        let habit: HabitDTO
        let sample: DateQuantitySample
    }
}

extension HabitGoalStatistics.HabitSamplePair {

    var exceedingGoalPercentage: Double {
        let unit = habit.unit
        let habitTarget = habit.quantity.doubleValue(for: unit)
        let sampleValue = sample.quantity.doubleValue(for: unit)

        let percentage = (sampleValue - habitTarget) / habitTarget

        return max(0, percentage)
    }

    var belowGoalPercentage: Double {
        let unit = habit.unit
        let habitTarget = habit.quantity.doubleValue(for: unit)
        let sampleValue = sample.quantity.doubleValue(for: unit)

        let percentage = (habitTarget - sampleValue) / habitTarget

        return max(0, percentage)
    }
}
