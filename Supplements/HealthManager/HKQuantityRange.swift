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
