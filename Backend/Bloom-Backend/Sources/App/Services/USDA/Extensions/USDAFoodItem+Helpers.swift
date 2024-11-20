//
//  File.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import BloomModel

private extension Int {
    static let protein = 1003
    static let fat = 1004
    static let carbohydrates = 1005
    static let calories = 2048
}

extension USDAFoodItem {

    func asFoodItem() -> FoodItem? {
        guard let name = description else { return nil }

        return FoodItem(
            id: FoodItemIdentifier("\(fdcId)"),
            name: name,
            brandName: foodCategory,
            flavour: nil,
            nutrients: toNutrients(),
            servingName: nil,
            servingQuantity: nil,
            ingredients: nil,
            isVerified: false
        )
    }

    func toNutrients() -> [FoodItem.Nutrient] {
        var newNutrients = [FoodItem.Nutrient]()

        if let nutrient = foodNutrients.first(where: { $0.nutrientId == .protein }), let value = nutrient.value {
            newNutrients.append(
                FoodItem.Nutrient(
                    kind: .protein,
                    quantity: .init(value: value, unit: "g")
                )
            )
        }
        if let nutrient = foodNutrients.first(where: { $0.nutrientId == .carbohydrates }), let value = nutrient.value {
            newNutrients.append(
                FoodItem.Nutrient(
                    kind: .carbohydrates,
                    quantity: .init(value: value, unit: "g")
                )
            )
        }
        if let nutrient = foodNutrients.first(where: { $0.nutrientId == .fat }), let value = nutrient.value {
            newNutrients.append(
                FoodItem.Nutrient(
                    kind: .fat,
                    quantity: .init(value: value, unit: "g")
                )
            )
        }
        if let nutrient = foodNutrients.first(where: { $0.nutrientId == .calories }), let value = nutrient.value {
            newNutrients.append(
                FoodItem.Nutrient(
                    kind: .calories,
                    quantity: .init(value: value, unit: "kcal")
                )
            )
        }

        return newNutrients
    }
}
