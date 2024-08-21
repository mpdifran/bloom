//
//  WorkoutTypeHeartRateReport.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import Foundation
import HealthKit

struct WorkoutTypeHeartRateReport: Identifiable, Hashable {
    var id: Int { hashValue }

    let workouts: [HKWorkout]
    let heartRateSamples: [HKQuantitySample]
    let heartRateZones: HeartRateZones
}

extension WorkoutTypeHeartRateReport {

    func appending(workoutReport: WorkoutHeartRateReport) -> WorkoutTypeHeartRateReport {
        WorkoutTypeHeartRateReport(
            workouts: workouts + [workoutReport.workout],
            heartRateSamples: heartRateSamples + workoutReport.heartRateSamples,
            heartRateZones: workoutReport.heartRateZones
        )
    }

    func heartRateDistribution() -> WorkoutHeartRateReport.WorkoutHeartZoneDistribution {
        var zone1 = 0
        var zone2 = 0
        var zone3 = 0
        var zone4 = 0
        var zone5 = 0

        for heartRateSample in heartRateSamples {
            let bpm = heartRateSample.quantity.doubleValue(for: .bpm())
            if bpm < heartRateZones.zone1 {
                continue
            } else if bpm < heartRateZones.zone2 {
                zone1 += 1
            } else if bpm < heartRateZones.zone3 {
                zone2 += 1
            } else if bpm < heartRateZones.zone4 {
                zone3 += 1
            } else if bpm < heartRateZones.zone5 {
                zone4 += 1
            } else {
                zone5 += 1
            }
        }

        let totalDuration = workouts.sum(keyPath: \.duration)

        return WorkoutHeartRateReport.WorkoutHeartZoneDistribution(
            totalDuration: HKQuantity(unit: .second(), doubleValue: totalDuration),
            zone1: HKQuantity(unit: .minute(), doubleValue: Double(zone1)),
            zone2: HKQuantity(unit: .minute(), doubleValue: Double(zone2)),
            zone3: HKQuantity(unit: .minute(), doubleValue: Double(zone3)),
            zone4: HKQuantity(unit: .minute(), doubleValue: Double(zone4)),
            zone5: HKQuantity(unit: .minute(), doubleValue: Double(zone5))
        )
    }
}
