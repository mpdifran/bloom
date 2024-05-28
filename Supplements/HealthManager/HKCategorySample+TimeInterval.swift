//
//  HKCategorySample+TimeInterval.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import HealthKit

extension HKCategorySample {

    var timeInterval: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    open override var debugDescription: String {
        guard let category = HKCategoryValueSleepAnalysis(rawValue: value) else {
            return "Unknown Sleep Category"
        }

        return "\(category.name) : \(timeInterval) seconds\nStart:\t\(DateFormatter.standardMedium.string(from: startDate))\nEnd:\t\(DateFormatter.standardMedium.string(from: endDate))\n"
    }

    var sleepCategory: HKCategoryValueSleepAnalysis? {
        HKCategoryValueSleepAnalysis(rawValue: value)
    }
}
