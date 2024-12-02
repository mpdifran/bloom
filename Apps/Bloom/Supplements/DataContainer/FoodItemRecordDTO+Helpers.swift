//
//  FoodItemRecordDTO+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-27.
//

import BloomModel
import DataContainer

extension FoodItemDTO {

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
            country: nil, // TODO: Fill this in
            calories: .init(value: calories, unit: "kcal"),
            protein: .init(value: protein, unit: "g"),
            carbohydrates: .init(value: carbohydrates, unit: "g"),
            fat: .init(value: fat, unit: "g"),
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
