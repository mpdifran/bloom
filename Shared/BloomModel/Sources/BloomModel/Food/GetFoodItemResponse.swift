//
//  GetFoodItemResponse.swift
//  bloom-model
//
//  Created by Claude Code on 2025-10-23.
//

import Foundation

public struct GetFoodItemResponse: Codable, Sendable {
    public let foodItem: FoodItem

    public init(foodItem: FoodItem) {
        self.foodItem = foodItem
    }
}
