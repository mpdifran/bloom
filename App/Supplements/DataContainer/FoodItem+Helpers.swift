//
//  FoodItem+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import DataContainer
import BloomModel

extension FoodItemRecord {

    convenience init(foodItem: FoodItem) {
        self.init(
            id: foodItem.id.value,
            name: foodItem.name,
            brandName: foodItem.brandName ?? "",
            flavour: foodItem.flavour ?? "",
            calories: foodItem.calories?.value ?? 0,
            protein: foodItem.protein?.value ?? 0,
            carbohydrates: foodItem.carbohydrates?.value ?? 0,
            fat: foodItem.fat?.value ?? 0,
            servingName: foodItem.servingName,
            servingUnitString: foodItem.servingQuantity?.unit,
            servingValue: foodItem.servingQuantity?.value,
            ingredients: foodItem.ingredients,
            isVerified: foodItem.isVerified,
            logs: []
        )
    }
}
