//
//  TargetMetricRecommendation.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-01.
//

import HealthKit

struct TargetMetricRecommendation: Sendable {
    let target: HKQuantity
    let context: String
}
