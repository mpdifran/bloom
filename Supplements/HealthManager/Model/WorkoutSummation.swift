//
//  WorkoutSummation.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-09.
//

import Foundation
import HealthKit

struct WorkoutSummation: Hashable, Identifiable {
    var id: Int { hashValue }

    let activityType: HKWorkoutActivityType
    let totalCalories: Double
    let instances: Int
}
