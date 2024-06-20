//
//  DateQuantitySample.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-05.
//

import Foundation
import OpenAPIClient

struct DateQuantitySample: Identifiable, Codable, Hashable {
    var id: String { "\(date)-\(quantity)" }

    let date: Date
    var quantity: Double
    let unit: String
}

extension DateQuantitySample {

    var healthMetricSample: HealthMetricSample {
        HealthMetricSample(
            date: date,
            quantity: quantity,
            unit: unit
        )
    }
}
