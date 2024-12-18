//
//  HealthWorkoutFetcher.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import Foundation
import HealthKit
import BloomFoundation

final actor HealthWorkoutFetcher {
  static let shared = HealthWorkoutFetcher()

  private let healthStore = HKHealthStore()
}

extension HealthWorkoutFetcher {

  func fetchSectionedWorkouts(activityType: HKWorkoutActivityType? = nil, dateRange: DateRange) async -> [WorkoutDateSection] {
    let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityType: activityType, dateRange: dateRange)

    var groupedWorkouts = [Date: [HKWorkout]]()
    let calendar = Calendar.current

    for workout in workouts {
      guard let monthDate = calendar.startOfMonth(for: workout.startDate) else { continue }

      groupedWorkouts[monthDate, default: []].append(workout)
    }

    let sections: [WorkoutDateSection] = groupedWorkouts.map { monthDate, workouts in
      let sortedWorkouts = workouts.sorted { $0.startDate > $1.startDate }
      return WorkoutDateSection(date: monthDate, workouts: sortedWorkouts)
    }
      .sorted { $0.date > $1.date }

    return sections
  }
}
