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
            String(localized: "In Bed", bundle: Bundle.coreHealth)
        case .asleepUnspecified:
            String(localized: "Asleep", bundle: Bundle.coreHealth)
        case .asleep:
            String(localized: "Asleep", bundle: Bundle.coreHealth)
        case .awake:
            String(localized: "Awake", bundle: Bundle.coreHealth)
        case .asleepCore:
            String(localized: "Core Sleep", bundle: Bundle.coreHealth)
        case .asleepDeep:
            String(localized: "Deep Sleep", bundle: Bundle.coreHealth)
        case .asleepREM:
            String(localized: "REM Sleep", bundle: Bundle.coreHealth)
        @unknown default:
            String(localized: "Unknown", bundle: Bundle.coreHealth)
        }
    }
}
