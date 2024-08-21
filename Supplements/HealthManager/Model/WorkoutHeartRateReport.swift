//
//  WorkoutHeartRateReport.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import Foundation
import HealthKit

struct WorkoutHeartRateReport: Identifiable, Hashable {
    var id: Int { hashValue }

    let workout: HKWorkout
    let heartRateSamples: [HKQuantitySample]
    let heartRateZones: HeartRateZones
}

extension WorkoutHeartRateReport {

    var normalizedDate: Date {
        Calendar.current.startOfDay(for: workout.endDate)
    }

    func heartRateDistribution() -> WorkoutHeartZoneDistribution {
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

        return WorkoutHeartZoneDistribution(
            totalDuration: HKQuantity(unit: .second(), doubleValue: workout.duration),
            zone1: HKQuantity(unit: .minute(), doubleValue: Double(zone1)),
            zone2: HKQuantity(unit: .minute(), doubleValue: Double(zone2)),
            zone3: HKQuantity(unit: .minute(), doubleValue: Double(zone3)),
            zone4: HKQuantity(unit: .minute(), doubleValue: Double(zone4)),
            zone5: HKQuantity(unit: .minute(), doubleValue: Double(zone5))
        )
    }
}

extension WorkoutHeartRateReport {
    struct WorkoutHeartZoneDistribution {
        let totalDuration: HKQuantity
        let zone1: HKQuantity
        let zone2: HKQuantity
        let zone3: HKQuantity
        let zone4: HKQuantity
        let zone5: HKQuantity
    }
}

extension WorkoutHeartRateReport.WorkoutHeartZoneDistribution {

    var zone1Percent: Double {
        zone1.doubleValue(for: .minute()) / totalDuration.doubleValue(for: .minute())
    }

    var zone2Percent: Double {
        zone2.doubleValue(for: .minute()) / totalDuration.doubleValue(for: .minute())
    }

    var zone3Percent: Double {
        zone3.doubleValue(for: .minute()) / totalDuration.doubleValue(for: .minute())
    }

    var zone4Percent: Double {
        zone4.doubleValue(for: .minute()) / totalDuration.doubleValue(for: .minute())
    }

    var zone5Percent: Double {
        zone5.doubleValue(for: .minute()) / totalDuration.doubleValue(for: .minute())
    }

    var maxPercent: Double {
        let values = [
            zone1Percent,
            zone2Percent,
            zone3Percent,
            zone4Percent,
            zone5Percent
        ]
        return values.max() ?? 1
    }
}
