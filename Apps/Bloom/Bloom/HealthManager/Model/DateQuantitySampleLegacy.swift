//
//  DateQuantitySampleLegacy.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-05.
//

import Foundation

struct DateQuantitySampleLegacy: Identifiable, Codable, Hashable {
    var id: String { "\(date)-\(quantity)" }

    let date: Date
    var quantity: Double
    let unit: String
}
