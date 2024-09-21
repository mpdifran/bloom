//
//  Habit+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import HealthKit
import DataContainer

extension Habit {

    var displayQuantity: String {
        quantity.displayString(for: unit, formatter: targetMetric.preferredFormatter)
    }
}
