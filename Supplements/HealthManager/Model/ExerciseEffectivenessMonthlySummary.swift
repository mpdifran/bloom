//
//  ExerciseEffectivenessMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import SwiftUI
import HealthKit

extension Double {
    static let minZone2Minutes: Double = 480
    static let minZone3Minutes: Double = 240
    static let minZone4Minutes: Double = 120
    static let minZone5Minutes: Double = 40
}

extension ExerciseEffectivenessMonthlySummary {
    enum Level {
        case ineffective
        case beginner
        case imbalanced
        case effective

        var name: String {
            switch self {
            case .ineffective:
                "Ineffective"
            case .beginner:
                "Beginner"
            case .imbalanced:
                "Imbalanced"
            case .effective:
                "Effective"
            }
        }

        var color: Color {
            switch self {
            case .ineffective:
                    .pink
            case .beginner:
                    .yellow
            case .imbalanced:
                    .yellow
            case .effective:
                    .green
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
    }
}

extension ExerciseEffectivenessMonthlySummary.Details {

    var score: Double {
        zoneScores.average(keyPath: \.0)
    }

    var zoneScores: [(Double, String)] {
        let distribution = overallHeartZoneDistribution

        let zone2Score = distribution.zone2.doubleValue(for: .minute()).scaledPercent(lower: 0, upper: .minZone2Minutes)
        let zone3Score = distribution.zone3.doubleValue(for: .minute()).scaledPercent(lower: 0, upper: .minZone3Minutes)
        let zone4Score = distribution.zone4.doubleValue(for: .minute()).scaledPercent(lower: 0, upper: .minZone4Minutes)
        let zone5Score = distribution.zone5.doubleValue(for: .minute()).scaledPercent(lower: 0, upper: .minZone5Minutes)

        return [
            (zone2Score, "Heart Rate Zone 2"),
            (zone3Score, "Heart Rate Zone 3"),
            (zone4Score, "Heart Rate Zone 4"),
            (zone5Score, "Heart Rate Zone 5")
        ]
    }

    var subtitle: String {
        if score < 1 {
            if let minZoneScore = zoneScores.min(by: { $0.0 < $1.0 }) {
                return "Insufficient \(minZoneScore.1) Coverage"
            }
            return "Imbalanced Target Heart Rate Zones"
        }

        return "Effective Target Heart Rate Zone Coverage"
    }

    var level: ExerciseEffectivenessMonthlySummary.Level {
        if score < 0.01 {
            return .ineffective
        } else if score < 0.5 {
            return .beginner
        } else if score < 1 {
            return .imbalanced
        }
        return .effective
    }

    func workoutTypeHeartRateReports() -> [WorkoutTypeHeartRateReport] {
        var workoutTypeReports = [WorkoutTypeHeartRateReport]()
        for workoutReport in workoutReports {
            if let existingReportIndex = workoutTypeReports.firstIndex(where: {
                $0.workouts.first?.workoutActivityType == workoutReport.workout.workoutActivityType
            }) {
                let report = workoutTypeReports.remove(at: existingReportIndex)
                let newReport = report.appending(workoutReport: workoutReport)
                workoutTypeReports.insert(newReport, at: existingReportIndex)
            } else {
                let report = WorkoutTypeHeartRateReport(
                    workouts: [workoutReport.workout],
                    heartRateSamples: workoutReport.heartRateSamples,
                    heartRateZones: workoutReport.heartRateZones
                )
                workoutTypeReports.append(report)
            }
        }
        return workoutTypeReports
    }

    var overallHeartZoneDistribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution {
        var totalTime: Double = 0
        var zone1: Double = 0
        var zone2: Double = 0
        var zone3: Double = 0
        var zone4: Double = 0
        var zone5: Double = 0

        for workoutReport in workoutReports {
            let distribution = workoutReport.heartRateDistribution()

            totalTime += distribution.totalDuration.doubleValue(for: .minute())
            zone1 += distribution.zone1.doubleValue(for: .minute())
            zone2 += distribution.zone2.doubleValue(for: .minute())
            zone3 += distribution.zone3.doubleValue(for: .minute())
            zone4 += distribution.zone4.doubleValue(for: .minute())
            zone5 += distribution.zone5.doubleValue(for: .minute())
        }

        return .init(
            totalDuration: HKQuantity(unit: .minute(), doubleValue: totalTime),
            zone1: HKQuantity(unit: .minute(), doubleValue: zone1),
            zone2: HKQuantity(unit: .minute(), doubleValue: zone2),
            zone3: HKQuantity(unit: .minute(), doubleValue: zone3),
            zone4: HKQuantity(unit: .minute(), doubleValue: zone4),
            zone5: HKQuantity(unit: .minute(), doubleValue: zone5)
        )
    }
}
