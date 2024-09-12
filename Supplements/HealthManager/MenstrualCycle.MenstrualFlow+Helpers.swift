//
//  MenstrualCycle.MenstrualFlow+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import HealthKit

extension MenstrualCycle.MenstrualFlow {

    var marksBeginningOfCycle: Bool {
        switch self {
        case .medium, .heavy:
            return true
        default:
            return false
        }
    }
}
