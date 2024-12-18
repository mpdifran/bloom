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

  var totalDistanceWalkingRunning: HKQuantity? {
    statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity()
  }

  var totalDistanceCycling: HKQuantity? {
    statistics(for: HKQuantityType(.distanceCycling))?.sumQuantity()
  }

  var totalDistanceWalkingRunningCycling: HKQuantity? {
    let totalDistance = (totalDistanceWalkingRunning?.doubleValue(for: .meter()) ?? 0) + (totalDistanceCycling?.doubleValue(for: .meter()) ?? 0)

    if totalDistance < 1 {
      return nil
    }
    return HKQuantity(unit: .meter(), doubleValue: totalDistance)
  }

  var duration: TimeInterval {
    endDate.timeIntervalSince(startDate)
  }

  var dateRange: DateRange {
    DateRange(startDate, endDate)
  }
}
