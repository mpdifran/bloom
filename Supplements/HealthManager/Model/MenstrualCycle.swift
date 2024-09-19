//
//  MenstrualCycle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import Foundation
@preconcurrency import HealthKit

extension MenstrualCycle {
    enum MenstrualFlow: Int {
        case unspecified = 1
        case light = 2
        case medium = 3
        case heavy = 4
        case none = 5
    }
}

struct MenstrualCycle: Hashable, Identifiable, Sendable {
    var id: Int { hashValue }

    let startDate: Date
    let samples: [HKCategorySample]
}

extension MenstrualCycle {

    var menstruationDurationDays: Int? {
        guard
            let start = samples.min(keyPath: \.startDate),
            let end = samples.max(keyPath: \.endDate)
        else { return nil }

        if let days = Calendar.current.dateComponents([.day], from: start, to: end).day {
            return days + 1
        }
        return nil
    }
}
