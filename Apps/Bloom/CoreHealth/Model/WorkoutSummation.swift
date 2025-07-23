//
//  WorkoutSummation.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-09.
//

import Foundation
import HealthKit

public struct WorkoutSummation: Hashable, Identifiable, Sendable {
  public var id: Int { hashValue }

  public let activityType: HKWorkoutActivityType
  public let totalCalories: Double
  public let instances: Int

  public init(
    activityType: HKWorkoutActivityType,
    totalCalories: Double,
    instances: Int
  ) {
    self.activityType = activityType
    self.totalCalories = totalCalories
    self.instances = instances
  }
}
