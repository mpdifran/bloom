//
//  FoodItemLog+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import DataContainer
import BloomModel

extension FoodItemRecord {

    func asNetworkFoodItem() -> FoodItem {
        let quantity: FoodItem.Quantity?
        if let servingValue, let servingUnitString {
            quantity = .init(
                value: servingValue,
                unit: servingUnitString
            )
        } else {
            quantity = nil
        }

        return FoodItem(
            id: .init(id),
            name: name,
            brandName: brandName,
            flavour: flavour,
            calories: .init(value: calories, unit: "kcal"),
            protein: .init(value: protein, unit: "g"),
            carbohydrates: .init(value: carbohydrates, unit: "g"),
            fat: .init(value: fat, unit: "g"),
            servingName: servingName,
            servingQuantity: quantity,
            ingredients: ingredients,
            isVerified: isVerified
        )
    }
}
