//
//  HabitGoalStatistics.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-21.
//

import DataContainer

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
    struct HabitSamplePair {
        let habit: Habit
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
