//
//  UploadNewFoodResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-12.
//

import Foundation

public struct UploadNewFoodResponse: Codable {
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
    public enum Result: String, Codable {
        case foodLogged
        case unclearNutritionLabel
        case unclearPackaging
    }
}
