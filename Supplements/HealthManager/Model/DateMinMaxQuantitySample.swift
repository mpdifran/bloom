//
//  DateMinMaxQuantitySample.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-25.
//

import Foundation

struct DateMinMaxQuantitySample: Identifiable, Codable, Hashable {
    var id: String { "\(date)-\(minQuantity)-\(maxQuantity)-\(unit)" }

    let date: Date
    var minQuantity: Double
    var maxQuantity: Double
    let unit: String
}
