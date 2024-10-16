//
//  Measurement+Locale.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-15.
//

import Foundation
import HealthKit

extension Measurement where UnitType == UnitTemperature {

    var localizedValue: Double {
        converted(to: UnitTemperature(forLocale: .current)).value
    }
}
