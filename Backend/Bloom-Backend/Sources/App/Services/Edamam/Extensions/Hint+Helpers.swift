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
            calories: food?.calories.map({ .init(value: $0, unit: "kcal") }),
            protein: food?.calories.map({ .init(value: $0, unit: "g") }),
            carbohydrates: food?.calories.map({ .init(value: $0, unit: "g") }),
            fat: food?.calories.map({ .init(value: $0, unit: "g") }),
            servingName: nil, // TODO: Implement?
            servingQuantity: servingSizes.first,
            ingredients: food?.foodContentsLabel,
            isVerified: false
        )
    }
}
