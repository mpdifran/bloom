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
            String(localized: "In Bed", bundle: Bundle.coreHealth, comment: "Display name for category value sleep analysis")
        case .asleepUnspecified:
            String(localized: "Asleep", bundle: Bundle.coreHealth, comment: "Display name for category value sleep analysis")
        case .asleep:
            String(localized: "Asleep", bundle: Bundle.coreHealth, comment: "Display name for category value sleep analysis")
        case .awake:
            String(localized: "Awake", bundle: Bundle.coreHealth, comment: "Display name for category value sleep analysis")
        case .asleepCore:
            String(localized: "Core Sleep", bundle: Bundle.coreHealth, comment: "Display name for category value sleep analysis")
        case .asleepDeep:
            String(localized: "Deep Sleep", bundle: Bundle.coreHealth, comment: "Display name for category value sleep analysis")
        case .asleepREM:
            String(localized: "REM Sleep", bundle: Bundle.coreHealth, comment: "Display name for category value sleep analysis")
        @unknown default:
            String(localized: "Unknown", bundle: Bundle.coreHealth, comment: "Display name for category value sleep analysis")
        }
    }
}
