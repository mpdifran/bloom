//
//  DateQuantitySample.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-05.
//

import Foundation

struct DateQuantitySample: Identifiable {
    var id: String { "\(date)-\(quantity)" }

    let date: Date
    let quantity: Double
}
