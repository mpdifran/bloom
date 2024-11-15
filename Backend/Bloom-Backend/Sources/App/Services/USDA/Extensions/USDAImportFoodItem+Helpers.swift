//
//  USDAImportFoodItem+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Foundation
import Vapor

extension USDAImportFoodItem {

    func asFoodItemRecord(request: Request, category: FoodItemRecord.Category) -> FoodItemRecord? {
        guard description.isNotEmpty else { return nil }

        let foodItemRecord = FoodItemRecord(
            id: "\(fdcId)",
            name: description,
            country: .usa, // Assuming all USDA items are from the USA.
            category: category
        )

        foodItemRecord.brandName = foodCategory.description

        if let nutrientAmount = foodNutrients.first(where: { $0.nutrient.id == 1008 })?.amount { // Calories
            foodItemRecord.calories = nutrientAmount // TODO: We're assuming kcals
        }
        if let nutrientAmount = foodNutrients.first(where: { $0.nutrient.id == 1003 })?.amount { // Protein
            foodItemRecord.protein = nutrientAmount // TODO: We're assuming g
        }
        if let nutrientAmount = foodNutrients.first(where: { $0.nutrient.id == 1005 })?.amount { // Carbs
            foodItemRecord.carbohydrates = nutrientAmount // TODO: We're assuming g
        }
        if let nutrientAmount = foodNutrients.first(where: { $0.nutrient.id == 1004 })?.amount { // Fat
            foodItemRecord.fat = nutrientAmount // TODO: We're assuming g
        }

        if let portion = foodPortions.first {
            var servingName = "\(portion.amount.prettyFormat()) \(portion.measureUnit.name)"
            if let modifier = portion.modifier, modifier.isNotEmpty {
                servingName += " (\(modifier))"
            }
            foodItemRecord.servingName = servingName
            foodItemRecord.servingValue = portion.gramWeight
            foodItemRecord.servingUnit = "g"
        } else {
            foodItemRecord.servingName = "100 g"
            foodItemRecord.servingValue = 100
            foodItemRecord.servingUnit = "g"
        }

        return foodItemRecord
    }
}
