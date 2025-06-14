//
//  FoodItemServingAmount.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-24.
//

import Foundation
import BloomModel

struct FoodItemServingAmount: Identifiable, Hashable, Sendable {
    var id: String { foodItem.id.value }

    var serving: Double
    let foodItem: FoodItem
}

extension EstimateFoodCaloriesResponse.Serving {

    func asServing() -> FoodItemServingAmount {
        FoodItemServingAmount(serving: servings, foodItem: item)
    }
}
