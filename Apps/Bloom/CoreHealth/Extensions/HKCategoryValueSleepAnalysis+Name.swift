//
//  HKCategoryValueSleepAnalysis+Name.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import HealthKit

public extension HKCategoryValueSleepAnalysis {

    var name: String {
        switch self {
        case .inBed:
            "In Bed"
        case .asleepUnspecified:
            "Asleep"
        case .asleep:
            "Asleep"
        case .awake:
            "Awake"
        case .asleepCore:
            "Core Sleep"
        case .asleepDeep:
            "Deep Sleep"
        case .asleepREM:
            "REM Sleep"
        @unknown default:
            "Unknown"
        }
    }
}
