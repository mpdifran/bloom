//
//  OpenAINutritionLabelParseResponse.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-12.
//

import Foundation

struct OpenAINutritionLabelParseResponse: Codable {
    // The serving name e.g. 1 bottle or 2 brownies
    let servingName: String
    // The value of the serving in a measurable quantity (e.g. 500 ml)
    let servingValue: Quantity
    let calories: Quantity
    let fat: Quantity
    let carbohydrate: Quantity
    let protein: Quantity
}

extension OpenAINutritionLabelParseResponse {
    struct Quantity: Codable {
        let value: Double
        // Unit like lbs, ml, oz
        let unit: String
    }
}
