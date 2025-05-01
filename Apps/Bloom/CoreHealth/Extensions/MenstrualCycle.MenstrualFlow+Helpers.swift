//
//  MenstrualCycle.MenstrualFlow+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import HealthKit

public extension MenstrualCycle.MenstrualFlow {

    var marksBeginningOfCycle: Bool {
        switch self {
        case .medium, .heavy, .unspecified:
            return true
        default:
            return false
        }
    }
}
