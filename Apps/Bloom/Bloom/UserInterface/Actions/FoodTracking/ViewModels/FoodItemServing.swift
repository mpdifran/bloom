//
//  FoodItemServing.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-24.
//

import Foundation
import BloomModel

struct FoodItemServing: Identifiable, Equatable {
    var id: String { foodItem.id.value }

    var serving: Double
    let foodItem: FoodItem
}

extension EstimateFoodCaloriesResponse.Serving {

    func asServing() -> FoodItemServing {
        FoodItemServing(serving: servings, foodItem: item)
    }
}
