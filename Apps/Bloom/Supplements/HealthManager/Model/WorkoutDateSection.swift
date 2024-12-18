//
//  WorkoutDateSection.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import HealthKit

struct WorkoutDateSection: Identifiable, Hashable {
  var id: Int { hashValue }

  let date: Date
  let workouts: [HKWorkout]
}
