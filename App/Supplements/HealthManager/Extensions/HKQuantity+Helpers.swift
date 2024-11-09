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

    @MainActor
    func displayString(for unit: HKUnit, formatter: NumberFormatter = NumberFormatter.noDecimalPlaces) -> String {
        let localizedUnit = unit.localizedUnit()
        let localizedValue = localizedValue(for: unit)
        return "\(formatter.string(for: localizedValue) ?? "") \(localizedUnit.sensibleUnitString)"
    }

    @MainActor
    func localizedValue(for unit: HKUnit) -> Double {
        doubleValue(for: unit.localizedUnit())
    }

    func sum(_ other: HKQuantity, unit: HKUnit) -> HKQuantity {
        let total = doubleValue(for: unit) + other.doubleValue(for: unit)

        return HKQuantity(unit: unit, doubleValue: total)
    }

    func subtract(_ other: HKQuantity, unit: HKUnit) -> HKQuantity {
        let total = doubleValue(for: unit) - other.doubleValue(for: unit)

        return HKQuantity(unit: unit, doubleValue: total)
    }
}
