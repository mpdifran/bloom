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
            brandName: "Generic",
            flavour: foodCategory,
            country: .usa,
            calories: calories.map({ .init(value: $0, unit: "kcal") }),
            protein: protein.map({ .init(value: $0, unit: "g") }),
            carbohydrates: carbohydrates.map({ .init(value: $0, unit: "g") }),
            fat: fat.map({ .init(value: $0, unit: "g") }),
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
            servingQuantity: nil,
            ingredients: nil,
            category: .generic,
            isVerified: false
        )
    }

    var calories: Double? {
        foodNutrients.first(where: { $0.nutrientId == .calories })?.value
    }

    var protein: Double? {
        foodNutrients.first(where: { $0.nutrientId == .protein })?.value
    }

    var carbohydrates: Double? {
        foodNutrients.first(where: { $0.nutrientId == .carbohydrates })?.value
    }

    var fat: Double? {
        foodNutrients.first(where: { $0.nutrientId == .fat })?.value
    }
}
