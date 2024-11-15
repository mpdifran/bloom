//
//  File.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-12.
//

import Foundation
import BloomModel

extension FoodItemRecord {

    func asFoodItem() -> FoodItem? {
        guard let id = id else { return nil }

        let servingQuantity: FoodItem.Quantity?
        if let servingValue, let servingUnit {
            servingQuantity = .init(value: servingValue, unit: servingUnit)
        } else {
            servingQuantity = nil
        }

        return FoodItem(
            id: FoodItemIdentifier(id),
            name: name,
            brandName: brandName,
            nutrients: toNutrients(),
            servingName: servingName,
            servingQuantity: servingQuantity,
            ingredients: nil
        )
    }

    func toNutrients() -> [FoodItem.Nutrient] {
        var nutrients = [FoodItem.Nutrient]()

        if let calories {
            nutrients.append(
                .init(kind: .calories, quantity: .init(value: calories, unit: "kcal"))
            )
        }
        if let protein {
            nutrients.append(
                .init(kind: .protein, quantity: .init(value: protein, unit: "g"))
            )
        }
        if let carbohydrates {
            nutrients.append(
                .init(kind: .carbohydrates, quantity: .init(value: carbohydrates, unit: "g"))
            )
        }
        if let fat {
            nutrients.append(
                .init(kind: .fat, quantity: .init(value: fat, unit: "g"))
            )
        }

        return nutrients
    }
}
