//
//  WorkoutDateSection.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import HealthKit

public struct WorkoutDateSection: Identifiable, Hashable {
  public var id: Date { date }

  public let date: Date
  public let workouts: [HKWorkout]

  public init(date: Date, workouts: [HKWorkout]) {
    self.date = date
    self.workouts = workouts
  }
}
