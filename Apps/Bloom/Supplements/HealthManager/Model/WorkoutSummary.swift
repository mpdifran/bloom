//
//  WorkoutSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-20.
//

import Foundation
import HealthKit

struct WorkoutSummary: Hashable, Identifiable {
  var id: Int { hashValue }

  let workout: HKWorkout
}

extension WorkoutSummary {

  var activeEnergyBurned: HKQuantity? {
    workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()
  }

  var distance: HKQuantity? {
    workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity()
  }
}
