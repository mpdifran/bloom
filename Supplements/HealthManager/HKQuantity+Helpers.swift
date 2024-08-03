//
//  HKQuantity+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-03.
//

import Foundation
import HealthKit

extension HKQuantity: Comparable {
    public static func < (lhs: HKQuantity, rhs: HKQuantity) -> Bool {
        lhs.compare(rhs) == .orderedAscending
    }
}

extension HKQuantity {

    static func closedRange(_ range: ClosedRange<Double>, unit: HKUnit) -> ClosedRange<HKQuantity> {
        HKQuantity(unit: unit, doubleValue: range.lowerBound)...HKQuantity(unit: unit, doubleValue: range.upperBound)
    }
}
