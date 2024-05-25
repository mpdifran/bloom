//
//  SleepAnalysis.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

struct SleepAnalysis: Codable, Hashable {
    let startDate: Date
    let endDate: Date
    let deepSleepMinutes: Double
    let coreSleepMinutes: Double
    let remSleepMinutes: Double
    let awakeSleepMinutes: Double
}
