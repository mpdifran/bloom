//
//  WorkoutTypeHeartRateReport.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import Foundation
import HealthKit

struct WorkoutTypeHeartRateReport: Identifiable, Hashable, Sendable {
    var id: Int { hashValue }

    let activityType: HKWorkoutActivityType
    let workoutCount: Int
    let heartZoneDistribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution
}

extension WorkoutTypeHeartRateReport {

    func appending(workoutReport: WorkoutHeartRateReport) -> WorkoutTypeHeartRateReport {
        return WorkoutTypeHeartRateReport(
            activityType: activityType,
            workoutCount: workoutCount + 1,
            heartZoneDistribution: heartZoneDistribution.sum(with: workoutReport.heartZoneDistribution)
        )
    }
}
