//
//  MenstrualCyclePhase.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import HealthKit

enum MenstrualCyclePhase {
    case follicular
    case ovulation
    case luteal
    case unknown
}

extension MenstrualCyclePhase {

    var name: String {
        switch self {
        case .follicular:
            "Follicular Phase"
        case .ovulation:
            "Ovulation Phase"
        case .luteal:
            "Luteal Phase"
        case .unknown:
            "Unknown"
        }
    }
}
