//
//  HealthWorkoutFetcher.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import Foundation
import HealthKit
import BloomFoundation

struct SectionedWorkoutResponse {
  let activityTypes: [HKWorkoutActivityType]
  let sections: [WorkoutDateSection]
}

final actor HealthWorkoutFetcher {
  static let shared = HealthWorkoutFetcher()

  private let healthStore = HKHealthStore()
}

extension HealthWorkoutFetcher {

  func fetchSectionedWorkouts(activityType: HKWorkoutActivityType? = nil, dateRange: DateRange) async -> SectionedWorkoutResponse {
    let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityType: activityType, dateRange: dateRange)

    var activityTypes = [HKWorkoutActivityType]()
    var groupedWorkouts = [Date: [HKWorkout]]()
    let calendar = Calendar.current

    for workout in workouts {
      guard let monthDate = calendar.startOfMonth(for: workout.startDate) else { continue }

      groupedWorkouts[monthDate, default: []].append(workout)

      if !activityTypes.contains(workout.workoutActivityType) {
        activityTypes.append(workout.workoutActivityType)
      }
    }

    let sections: [WorkoutDateSection] = groupedWorkouts.map { monthDate, workouts in
      let sortedWorkouts = workouts.sorted { $0.startDate > $1.startDate }
      return WorkoutDateSection(date: monthDate, workouts: sortedWorkouts)
    }
      .sorted { $0.date > $1.date }

    return SectionedWorkoutResponse(
      activityTypes: activityTypes,
      sections: sections
    )
  }
}
