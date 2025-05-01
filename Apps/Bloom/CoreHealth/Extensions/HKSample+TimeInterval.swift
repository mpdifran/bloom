//
//  HKSample+TimeInterval.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-12.
//

import Foundation
import HealthKit

public extension HKSample {

    var timeInterval: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
}
