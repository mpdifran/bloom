//
//  HKQuantity+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-03.
//

import Foundation
import HealthKit

extension HKQuantity: @retroactive Comparable {
    public static func < (lhs: HKQuantity, rhs: HKQuantity) -> Bool {
        lhs.compare(rhs) == .orderedAscending
    }
}

extension HKQuantity {

    func displayString(for unit: HKUnit, formatter: NumberFormatter = NumberFormatter.noDecimalPlaces) -> String {
        let doubleValue = doubleValue(for: unit)

        return "\(formatter.string(for: doubleValue) ?? "") \(unit.unitString)"
    }

    func sum(_ other: HKQuantity, unit: HKUnit) -> HKQuantity {
        let total = doubleValue(for: unit) + other.doubleValue(for: unit)

        return HKQuantity(unit: unit, doubleValue: total)
    }
}
