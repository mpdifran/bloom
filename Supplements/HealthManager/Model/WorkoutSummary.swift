//
//  WorkoutSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-20.
//

import Foundation
import OpenAPIClient

struct WorkoutSummary: Codable, Equatable, Identifiable {
    var id: String { "\(activity)-\(startDate)-\(durationSeconds)-\(caloriesBurned)" }
    let activity: String
    let startDate: Date
    let durationSeconds: TimeInterval
    let caloriesBurned: Double
}

extension WorkoutSummary {

    var healthWorkout: HealthWorkout {
        HealthWorkout(
            activity: activity,
            startDate: startDate,
            durationMinutes: durationSeconds / 60,
            caloriesBurned: caloriesBurned
        )
    }
}
