//
//  Hint+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation
import BloomModel

extension Components.Schemas.Hint {

    func asFoodItem() -> FoodItem? {
        let optionalName = food?.label ?? food?.knownAs

        guard
            let foodId = food?.foodId,
            let name = optionalName
        else { return nil }

        let servingSizes = food?.servingSizes?.compactMap({ $0.asFoodItemQuantity() }) ?? []

        return FoodItem(
            id: FoodItemIdentifier(foodId),
            name: name,
            brandName: food?.brand,
            flavour: nil,
            country: .usa, // TODO: This is an assumption
            calories: food?.calories.map({ .init(value: $0, unit: "kcal") }),
            protein: food?.protein.map({ .init(value: $0, unit: "g") }),
            carbohydrates: food?.carbohydrates.map({ .init(value: $0, unit: "g") }),
            fat: food?.fat.map({ .init(value: $0, unit: "g") }),
            saturatedFat: nil,
            transFat: nil,
            polyunsaturatedFat: nil,
            monounsaturatedFat: nil,
            fiber: nil,
            sugar: nil,
            cholesterol: nil,
            sodium: nil,
            calcium: nil,
            iron: nil,
            potassium: nil,
            magnesium: nil,
            zinc: nil,
            vitaminA: nil,
            vitaminB6: nil,
            vitaminB12: nil,
            vitaminC: nil,
            vitaminD: nil,
            vitaminE: nil,
            servingName: nil,
            servingQuantity: servingSizes.first,
            ingredients: food?.foodContentsLabel,
            category: .branded, // TODO: Don't assume this, look at the model data.
            isVerified: false
        )
    }
}
