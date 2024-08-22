//
//  ExerciseEffectivenessMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import SwiftUI
import HealthKit

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
                    .pink
            case .minimal:
                    .yellow
            case .moderate:
                    .green
            case .high:
                    .coreSleep
            }
        }
    }
}

struct ExerciseEffectivenessMonthlySummary {
    let details: Details
    let lastMonthDetails: Details

    var trend: VitalModel.Trend {
        details.score < lastMonthDetails.score ? .decreasing : .increasing
    }
}

extension ExerciseEffectivenessMonthlySummary {
    struct Details {
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

            self.overallHeartZoneDistribution = workoutReports.reduce(WorkoutHeartRateReport.WorkoutHeartZoneDistribution()) { partialResult, report in
                partialResult.sum(with: report.heartZoneDistribution)
            }

            var workoutTypeReports = [WorkoutTypeHeartRateReport]()
            for workoutReport in workoutReports {
                if let existingReportIndex = workoutTypeReports.firstIndex(where: {
                    $0.activityType == workoutReport.workout.workoutActivityType
                }) {
                    let report = workoutTypeReports.remove(at: existingReportIndex)
                    let newReport = report.appending(workoutReport: workoutReport)
                    workoutTypeReports.insert(newReport, at: existingReportIndex)
                } else {
                    let report = WorkoutTypeHeartRateReport(
                        activityType: workoutReport.workout.workoutActivityType,
                        workoutCount: 1,
                        heartZoneDistribution: workoutReport.heartZoneDistribution
                    )
                    workoutTypeReports.append(report)
                }
            }
            self.workoutTypeHeartRateReports = workoutTypeReports
        }
    }
}

extension ExerciseEffectivenessMonthlySummary.Details {

    var score: Double {
        let scaledDuration = overallHeartZoneDistribution.scaledDurationSum.doubleValue(for: .minute())
        return scaledDuration.scaledPercent(lower: 0, upper: .minZoneMinutes)
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
