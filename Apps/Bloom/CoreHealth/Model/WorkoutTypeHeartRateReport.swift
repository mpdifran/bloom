//
//  WorkoutTypeHeartRateReport.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import Foundation
import HealthKit

public struct WorkoutTypeHeartRateReport: Identifiable, Hashable, Sendable {
  public var id: Int { hashValue }

  public let activityType: HKWorkoutActivityType
  public let workoutCount: Int
  public let heartZoneDistribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution

  public init(
    activityType: HKWorkoutActivityType,
    workoutCount: Int,
    heartZoneDistribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution
  ) {
    self.activityType = activityType
    self.workoutCount = workoutCount
    self.heartZoneDistribution = heartZoneDistribution
  }
}

public extension WorkoutTypeHeartRateReport {

  func appending(workoutReport: WorkoutHeartRateReport) -> WorkoutTypeHeartRateReport {
    return WorkoutTypeHeartRateReport(
      activityType: activityType,
      workoutCount: workoutCount + 1,
      heartZoneDistribution: heartZoneDistribution.sum(with: workoutReport.heartZoneDistribution)
    )
  }
}
