//
//  HKWorkout+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import Foundation
import HealthKit
import BloomFoundation

public extension HKWorkout {

  var totalTimeString: String {
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.hour, .minute, .second]
      formatter.zeroFormattingBehavior = .pad
      return formatter.string(from: duration) ?? ""
  }

  var activeEnergyBurned: HKQuantity {
    if let energy = statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity() {
      return energy
    }
    return HKQuantity(unit: .largeCalorie(), doubleValue: 0)
  }

  var totalEnergyBurned: HKQuantity {
    let defaultQuantity = HKQuantity(unit: .largeCalorie(), doubleValue: 0)
    guard let activeEnergy = statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity() else {
      return defaultQuantity
    }
    guard let basalEnergy = statistics(for: HKQuantityType(.basalEnergyBurned))?.sumQuantity() else {
      return activeEnergy
    }
    return basalEnergy.sum(activeEnergy, unit: .largeCalorie())
  }

  var averageHeartRate: HKQuantity {
    let defaultQuantity = HKQuantity(unit: .bpm(), doubleValue: 0)
    guard
      let statistics = statistics(for: HKQuantityType(.heartRate)),
      let average = statistics.averageQuantity()
    else {
      return defaultQuantity
    }
    return average
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

  // TODO: Why do we have this??
//  var duration: TimeInterval {
//    endDate.timeIntervalSince(startDate)
//  }

  var dateRange: DateRange {
    DateRange(startDate, endDate)
  }
}
