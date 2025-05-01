//
//  HKCategorySample+TimeInterval.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import HealthKit

public extension HKCategorySample {

    open override var debugDescription: String {
        guard let category = HKCategoryValueSleepAnalysis(rawValue: value) else {
            return "Unknown Sleep Category"
        }

        return "\(category.name) : \(timeInterval) seconds\nStart:\t\(DateFormatter.dateTimeMedium.string(from: startDate))\nEnd:\t\(DateFormatter.dateTimeMedium.string(from: endDate))\n"
    }

    var sleepCategory: HKCategoryValueSleepAnalysis? {
        HKCategoryValueSleepAnalysis(rawValue: value)
    }

    var walkingSteadinessCategory: HKCategoryValueAppleWalkingSteadinessEvent? {
        HKCategoryValueAppleWalkingSteadinessEvent(rawValue: value)
    }

    var menstrualFlowCategory: MenstrualCycle.MenstrualFlow {
        MenstrualCycle.MenstrualFlow(rawValue: value) ?? .unspecified
    }
}
