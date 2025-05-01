//
//  HabitGoalStatistics.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-21.
//

import DataContainer
import HealthKit
import CoreHealth

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

        let newValue: Double
        let context: String

        if missedGoalCountPercentage > 0.4 {
            // decrease target
            newValue = existingHabit.value * (1 - (averagePercentMissedGoalBy / 2))
            context = "Looks like you haven't been hitting your goal recently. Let's set a more achievable goal."
        } else if missedGoalSamples.count < 3 {
            if existingHabit.targetMetric.idealRange?.contains(quantity: existingHabit.quantity) == true {
                // TODO: Promote to habit here?
                newValue = existingHabit.quantity.doubleValue(for: existingHabit.unit)
                context = "Way to continue hitting your goal! We'll keep your goal the same this week."
            } else {
                // increase target
                newValue = existingHabit.value * (1 + (averagePercentExceededGoalBy / 2))
                context = "Great job hitting your goal! Let's set a new goal to challenge you."
            }
        } else {
            // keep target the same
            newValue = existingHabit.quantity.doubleValue(for: existingHabit.unit)
            context = "Keep up the good work! We'll keep your goal the same this week."
        }

        let minValue = existingHabit.targetMetric.minHabitTarget.doubleValue(for: existingHabit.unit)
        let clampedValue = max(minValue, newValue.roundedToNiceNumber())

        return TargetMetricRecommendation(
            target: HKQuantity(unit: existingHabit.unit, doubleValue: clampedValue),
            context: context
        )
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
