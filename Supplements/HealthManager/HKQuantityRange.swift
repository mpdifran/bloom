//
//  HKQuantityRange.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-03.
//

import Foundation
import HealthKit

struct HKQuantityRange {
    let unit: HKUnit
    let range: ClosedRange<Double>
}

extension HKQuantityRange {

    var lower: HKQuantity {
        HKQuantity(unit: self.unit, doubleValue: range.lowerBound)
    }

    var upper: HKQuantity {
        HKQuantity(unit: self.unit, doubleValue: range.upperBound)
    }

    func lowerDoubleValue(for unit: HKUnit) -> Double {
        let quantity = HKQuantity(unit: self.unit, doubleValue: range.lowerBound)
        return quantity.doubleValue(for: unit)
    }

    func upperDoubleValue(for unit: HKUnit) -> Double {
        let quantity = HKQuantity(unit: self.unit, doubleValue: range.upperBound)
        return quantity.doubleValue(for: unit)
    }
}
