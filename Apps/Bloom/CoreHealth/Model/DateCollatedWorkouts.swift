//
//  DateCollatedWorkouts.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import Foundation
@preconcurrency import HealthKit

public struct DateCollatedWorkouts: Identifiable, Hashable, Sendable {
  public var id: Int { hashValue }

  public let date: Date
  public let workouts: [HKWorkout]

  public init(date: Date, workouts: [HKWorkout]) {
    self.date = date
    self.workouts = workouts
  }
}
