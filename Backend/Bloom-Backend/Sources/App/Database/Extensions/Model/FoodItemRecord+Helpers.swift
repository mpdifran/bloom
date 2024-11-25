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
            flavour: flavour,
            calories: calories.map({ .init(value: $0, unit: "kcal")}),
            protein: protein.map({ .init(value: $0, unit: "g")}),
            carbohydrates: carbohydrates.map({ .init(value: $0, unit: "g")}),
            fat: fat.map({ .init(value: $0, unit: "g")}),
            servingName: servingName,
            servingQuantity: servingQuantity,
            ingredients: nil,
            category: category.asCategory(),
            isVerified: state == .verified
        )
    }
}

extension FoodItemRecord.Category {

    func asCategory() -> FoodItem.Category {
        switch self {
        case .generic:
                .generic
        case .fastfood:
                .fastfood
        case .restaurant:
                .restaurant
        case .branded:
                .branded
        }
    }
}
