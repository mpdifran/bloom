//
//  SleepHealthSnapshot.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-03.
//

import Foundation

struct SleepHealthSnapshot: Codable {
    let timeInDaylight: [DateQuantitySample]
    let workouts: [WorkoutSummary]
    let sleepSummaries: [SleepAnalysis]
    let meditation: [DateQuantitySample]
    let restingHeartRate: [DateQuantitySample]
}
