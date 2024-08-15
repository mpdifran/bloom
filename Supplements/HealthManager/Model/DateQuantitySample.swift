//
//  DateQuantitySample.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import Foundation
import HealthKit

struct DateQuantitySample: Identifiable, Hashable {
    var id: Int { hashValue }

    let date: Date
    let quantity: HKQuantity
}
