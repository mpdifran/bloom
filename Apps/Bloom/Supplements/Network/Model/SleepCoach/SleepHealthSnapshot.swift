//
//  SleepHealthSnapshot.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-03.
//

import Foundation

struct SleepHealthSnapshot: Codable {
    let timeInDaylight: [DateQuantitySampleLegacy]
    let workouts: [WorkoutSummary]
    let sleepSummaries: [SleepAnalysis]
    let meditation: [DateQuantitySampleLegacy]
    let restingHeartRate: [DateQuantitySampleLegacy]
}
