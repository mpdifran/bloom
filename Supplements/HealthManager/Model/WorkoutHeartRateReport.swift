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
    let heartZoneDistribution: WorkoutHeartZoneDistribution

    init(
        workout: HKWorkout,
        heartRateSamples: [HKQuantitySample],
        heartRateZones: HeartRateZones
    ) {
        self.workout = workout
        self.heartRateSamples = heartRateSamples
        self.heartRateZones = heartRateZones

        var zoneDurations: [TimeInterval] = [0, 0, 0, 0, 0, 0]

        var currentZone = 0
        var zoneStartDate: Date?
        var zoneEndDate: Date?

        for heartRateSample in heartRateSamples {
            var sampleZone = 0
            let bpm = heartRateSample.quantity.doubleValue(for: .bpm())
            if bpm < heartRateZones.zone1 {
                sampleZone = 0
            } else if bpm < heartRateZones.zone2 {
                sampleZone = 1
            } else if bpm < heartRateZones.zone3 {
                sampleZone = 2
            } else if bpm < heartRateZones.zone4 {
                sampleZone = 3
            } else if bpm < heartRateZones.zone5 {
                sampleZone = 4
            } else {
                sampleZone = 5
            }

            if sampleZone != currentZone {
                if let startDate = zoneStartDate {
                    let duration = heartRateSample.startDate.timeIntervalSince(startDate)

                    zoneDurations[currentZone] += duration
                }
                currentZone = sampleZone
                zoneStartDate = heartRateSample.startDate
            }

            zoneEndDate = heartRateSample.startDate
        }

        // Add last entry
        if let zoneStartDate, let zoneEndDate {
            let duration = zoneEndDate.timeIntervalSince(zoneStartDate)
            zoneDurations[currentZone] += duration
        }

        self.heartZoneDistribution = WorkoutHeartZoneDistribution(
            totalDuration: HKQuantity(unit: .second(), doubleValue: workout.duration),
            zone1: HKQuantity(unit: .second(), doubleValue: max(zoneDurations[1], 0)),
            zone2: HKQuantity(unit: .second(), doubleValue: max(zoneDurations[2], 0)),
            zone3: HKQuantity(unit: .second(), doubleValue: max(zoneDurations[3], 0)),
            zone4: HKQuantity(unit: .second(), doubleValue: max(zoneDurations[4], 0)),
            zone5: HKQuantity(unit: .second(), doubleValue: max(zoneDurations[5], 0))
        )
    }
}

extension WorkoutHeartRateReport {

    var normalizedDate: Date {
        Calendar.current.startOfDay(for: workout.endDate)
    }
}

extension WorkoutHeartRateReport {
    struct WorkoutHeartZoneDistribution: Hashable {
        let totalDuration: HKQuantity
        let zone1: HKQuantity
        let zone2: HKQuantity
        let zone3: HKQuantity
        let zone4: HKQuantity
        let zone5: HKQuantity

        init(
            totalDuration: HKQuantity,
            zone1: HKQuantity,
            zone2: HKQuantity,
            zone3: HKQuantity,
            zone4: HKQuantity,
            zone5: HKQuantity
        ) {
            self.totalDuration = totalDuration
            self.zone1 = zone1
            self.zone2 = zone2
            self.zone3 = zone3
            self.zone4 = zone4
            self.zone5 = zone5
        }

        init() {
            self.totalDuration = HKQuantity(unit: .minute(), doubleValue: 0)
            self.zone1 = HKQuantity(unit: .minute(), doubleValue: 0)
            self.zone2 = HKQuantity(unit: .minute(), doubleValue: 0)
            self.zone3 = HKQuantity(unit: .minute(), doubleValue: 0)
            self.zone4 = HKQuantity(unit: .minute(), doubleValue: 0)
            self.zone5 = HKQuantity(unit: .minute(), doubleValue: 0)
        }
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

extension WorkoutHeartRateReport.WorkoutHeartZoneDistribution {

    func sum(with other: WorkoutHeartRateReport.WorkoutHeartZoneDistribution) -> WorkoutHeartRateReport.WorkoutHeartZoneDistribution {
        WorkoutHeartRateReport.WorkoutHeartZoneDistribution(
            totalDuration: totalDuration.sum(other.totalDuration, unit: .minute()),
            zone1: zone1.sum(other.zone1, unit: .minute()),
            zone2: zone2.sum(other.zone2, unit: .minute()),
            zone3: zone3.sum(other.zone3, unit: .minute()),
            zone4: zone4.sum(other.zone4, unit: .minute()),
            zone5: zone5.sum(other.zone5, unit: .minute())
        )
    }
}
