//
//  FoodItemServingAmount.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-24.
//

import Foundation
import BloomModel

public struct FoodItemServingAmount: Identifiable, Hashable, Sendable {
    public var id: String { foodItem.id.value }

    public var serving: Double
    public let foodItem: FoodItem

    public init(serving: Double, foodItem: FoodItem) {
        self.serving = serving
        self.foodItem = foodItem
    }
}

public extension EstimateFoodCaloriesResponse.Serving {

    func asServing() -> FoodItemServingAmount {
        FoodItemServingAmount(serving: servings, foodItem: item)
    }
}
