//
//  DateQuantitySample.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import Foundation
@preconcurrency import HealthKit

struct DateQuantitySample: Identifiable, Hashable, Sendable {
    var id: Int { hashValue }

    let date: Date
    let quantity: HKQuantity
}
