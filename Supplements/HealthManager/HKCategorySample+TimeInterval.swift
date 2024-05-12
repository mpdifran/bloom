//
//  HKCategorySample+TimeInterval.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import HealthKit

extension HKCategorySample {

    var timeInterval: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
}
