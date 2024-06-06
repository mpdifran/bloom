//
//  HeartRateSample.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import Foundation

struct HeartRateSample: Codable, Equatable, Identifiable {
    var id: String { "\(date) - \(value) - \(unit)" }

    let date: Date
    let value: Double
    let unit: String
}
