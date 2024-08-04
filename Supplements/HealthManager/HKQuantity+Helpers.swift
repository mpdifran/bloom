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

    func displayString(for unit: HKUnit, specifier: String = "%.0f") -> String {
        let doubleValue = doubleValue(for: unit)

        return "\(String(format: specifier, doubleValue)) \(unit.unitString)"
    }
}
