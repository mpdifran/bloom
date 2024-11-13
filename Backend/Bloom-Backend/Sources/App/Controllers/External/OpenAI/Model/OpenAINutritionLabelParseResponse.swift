//
//  OpenAINutritionLabelParseResponse.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-12.
//

import Foundation

struct OpenAINutritionLabelParseResponse: Codable {
    let servingName: String
    let servingValue: Quantity
    let calories: Quantity
    let fat: Quantity
    let carbohydrate: Quantity
    let protein: Quantity
}

extension OpenAINutritionLabelParseResponse {
    struct Quantity: Codable {
        let value: Double
        let unit: String
    }
}
