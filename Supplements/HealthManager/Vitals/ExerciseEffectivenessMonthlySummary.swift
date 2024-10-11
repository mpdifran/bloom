//
//  ExerciseEffectivenessMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import SwiftUI
import HealthKit
import DataContainer

/// https://www.heart.org/en/healthy-living/fitness/fitness-basics/aha-recs-for-physical-activity-in-adults
/// https://www.sciencealert.com/heart-rate-zones-explained-heres-how-to-optimize-your-exercise-routine
extension Double {
    static let maxMinimalZoneMinutes: Double = 300
    static let minZoneMinutes: Double = 600
    static let zone12Multiplier: Double = 1
    static let zone34Multiplier: Double = 2
    static let zone5Multiplier: Double = 3
}

extension ExerciseEffectivenessMonthlySummary {
    enum Level {
        case sedentary
        case minimal
        case moderate
        case high

        var name: String {
            switch self {
            case .sedentary:
                "Sedentary"
            case .minimal:
                "Minimal"
            case .moderate:
                "Moderate"
            case .high:
                "High"
            }
        }

        var color: Color {
            switch self {
            case .sedentary:
                    .vitalSevere
            case .minimal:
                    .vitalWarning
            case .moderate:
                    .vitalGood
            case .high:
                    .vitalGreat
            }
        }
    }
}

struct ExerciseEffectivenessMonthlySummary: Hashable, Sendable {
    let details: Details

    var barLevel: VitalModel.BarLevel? {
        let level = details.level
        let scaledSum = details.overallHeartZoneDistribution.scaledDurationSum

        let minutes = scaledSum.doubleValue(for: .minute())

        switch level {
        case .sedentary:
            return VitalModel.BarLevel(
                level: .low,
                proportion: 0.5
            )
        case .minimal:
            return VitalModel.BarLevel(
                level: .medium,
                proportion: minutes.scaledPercent(lower: 0, upper: .maxMinimalZoneMinutes)
            )
        case .moderate:
            return VitalModel.BarLevel(
                level: .high,
                proportion: minutes.scaledPercent(lower: .maxMinimalZoneMinutes, upper: .minZoneMinutes)
            )
        case .high:
            return VitalModel.BarLevel(
                level: .optimal,
                proportion: minutes.scaledPercent(lower: .minZoneMinutes, upper: .minZoneMinutes * 2)
            )
        }
    }
}

extension ExerciseEffectivenessMonthlySummary {
    struct Details: Hashable, Sendable {
        let heartRateZones: HeartRateZones
        let workoutReports: [WorkoutHeartRateReport]
        let overallHeartZoneDistribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution
        let workoutTypeHeartRateReports: [WorkoutTypeHeartRateReport]

        init(
            heartRateZones: HeartRateZones,
            workoutReports: [WorkoutHeartRateReport]
        ) {
            self.heartRateZones = heartRateZones
            self.workoutReports = workoutReports
            self.overallHeartZoneDistribution = workoutReports.generateOverallDistribution()
            self.workoutTypeHeartRateReports = workoutReports.generateWorkoutTypeHeartRateReports()
        }
    }
}

extension ExerciseEffectivenessMonthlySummary.Details {

    var score: Double {
        let scaledDuration = overallHeartZoneDistribution.scaledDurationSum.doubleValue(for: .minute())
        return scaledDuration.scaledPercent(lower: 0, upper: .minZoneMinutes)
    }

    var hasNoData: Bool {
        workoutReports.isEmpty
    }

    var subtitle: String {
        if score < 1 {
            let scaledDuration = overallHeartZoneDistribution.scaledDurationSum.doubleValue(for: .minute())
            let remainderDuration = Double.minZoneMinutes - scaledDuration

            return "\(remainderDuration.format()) zone minutes short"
        }
        return "Exercise Effective"
    }

    var level: ExerciseEffectivenessMonthlySummary.Level {
        if workoutReports.isEmpty {
            return .sedentary
        }

        let scaledSum = overallHeartZoneDistribution.scaledDurationSum

        if scaledSum.doubleValue(for: .minute()) < .maxMinimalZoneMinutes {
            return .minimal
        }
        if scaledSum.doubleValue(for: .minute()) < .minZoneMinutes {
            return .moderate
        }
        return .high
    }
}
