//
//  FoodItemRecord+Helpers.swift
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
            category: .init(rawValue: foodItem.category.rawValue),
            isVerified: foodItem.isVerified,
            logs: []
        )
    }
}

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
            category: networkCategory,
            isVerified: isVerified
        )
    }

    var networkCategory: FoodItem.Category {
        guard let dbCategory = self.category else { return .generic }

        return FoodItem.Category(rawValue: dbCategory.rawValue) ?? .generic
    }
}
