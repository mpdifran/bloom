//
//  WorkoutSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-20.
//

import Foundation
import HealthKit

public struct WorkoutSummary: Hashable, Identifiable {
  public var id: Int { hashValue }

  public let workout: HKWorkout

  public init(workout: HKWorkout) {
    self.workout = workout
  }
}

public extension WorkoutSummary {

  var activeEnergyBurned: HKQuantity? {
    workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()
  }

  var distance: HKQuantity? {
    workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity()
  }
}
