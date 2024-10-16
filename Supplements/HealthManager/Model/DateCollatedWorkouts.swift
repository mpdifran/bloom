//
//  DateCollatedWorkouts.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import Foundation
@preconcurrency import HealthKit

struct DateCollatedWorkouts: Identifiable, Hashable, Sendable {
    var id: Int { hashValue }

    let date: Date
    let workouts: [HKWorkout]
}
