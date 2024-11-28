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
    let protein: Quantity
    let carbohydrate: Quantity
    let fat: Quantity
    let saturatedFat: Quantity?
    let transFat: Quantity?
    let polyunsaturatedFat: Quantity?
    let monounsaturatedFat: Quantity?
    let fiber: Quantity?
    let sugar: Quantity?
    let cholesterol: Quantity?
    let sodium: Quantity?
    let calcium: Quantity?
    let iron: Quantity?
    let potassium: Quantity?
    let magnesium: Quantity?
    let zinc: Quantity?
    let vitaminA: Quantity?
    let vitaminB6: Quantity?
    let vitaminB12: Quantity?
    let vitaminC: Quantity?
    let vitaminD: Quantity?
    let vitaminE: Quantity?
}

extension OpenAINutritionLabelParseResponse {
    struct Quantity: Codable {
        let value: Double
        // Unit like lbs, ml, oz
        let unit: String
    }
}
