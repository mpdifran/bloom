//
//  UploadNewFoodResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-12.
//

import Foundation

public struct UploadNewFoodResponse: Codable, Sendable {
    public let result: Result
    public let foodItem: FoodItem?

    public init(
        result: Result,
        foodItem: FoodItem?
    ) {
        self.result = result
        self.foodItem = foodItem
    }
}

public extension UploadNewFoodResponse {
    enum Result: String, Codable, Sendable {
        case foodLogged
        case unclearNutritionLabel
        case unclearPackaging
    }
}
