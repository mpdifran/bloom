//
//  DateAverageQuantitySample.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-03.
//

import Foundation

struct DateAverageQuantitySample: Identifiable, Codable, Hashable {
    var id: String { "\(date)-\(averageQuantity)-\(unit)" }

    let date: Date
    var averageQuantity: Double
    let unit: String
}
