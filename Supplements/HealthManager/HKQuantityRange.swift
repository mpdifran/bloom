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

    func lowerDoubleValue(for unit: HKUnit) -> Double {
        let quantity = HKQuantity(unit: self.unit, doubleValue: range.lowerBound)
        return quantity.doubleValue(for: unit)
    }

    func upperDoubleValue(for unit: HKUnit) -> Double {
        let quantity = HKQuantity(unit: self.unit, doubleValue: range.upperBound)
        return quantity.doubleValue(for: unit)
    }
}
