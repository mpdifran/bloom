//
//  HKWorkout+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import Foundation
import HealthKit
import BloomFoundation

extension HKWorkout {

    var totalEnergyBurned: HKQuantity {
        if let energy = statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity() {
            return energy
        }
        return HKQuantity(unit: .largeCalorie(), doubleValue: 0)
    }

    var totalDistanceWalkingRunning: HKQuantity {
        if let distance = statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity() {
            return distance
        }
        return HKQuantity(unit: .meter(), doubleValue: 0)
    }

    var totalDistanceCycling: HKQuantity {
        if let distance = statistics(for: HKQuantityType(.distanceCycling))?.sumQuantity() {
            return distance
        }
        return HKQuantity(unit: .meter(), doubleValue: 0)
    }

    var totalDistanceWalkingRunningCycling: HKQuantity {
        let totalDistance = totalDistanceWalkingRunning.doubleValue(for: .meter()) + totalDistanceCycling.doubleValue(for: .meter())
        return HKQuantity(unit: .meter(), doubleValue: totalDistance)
    }

    var dateRange: DateRange {
        DateRange(startDate, endDate)
    }
}
