//
//  OpenAIEstimateCaloriesResponse.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-14.
//

import Foundation
import BloomModel

struct OpenAIEstimateCaloriesResponse: Codable {
  let items: [Item]
}


extension OpenAIEstimateCaloriesResponse {
    struct Item: Codable {
        let name: String
        let servingName: String
        let servingAmountUnit: String
        let servingAmount: Double
        let servingCount: Double
        let calories: Double
        let fat: Double
        let carbs: Double
        let protein: Double
    }

    struct Quantity: Codable {
        let value: Double
        let unit: String
    }
}

extension OpenAIEstimateCaloriesResponse.Item {

    func asServing() -> EstimateFoodCaloriesResponse.Serving {
        .init(servings: servingCount,
              item: asFoodItem())
    }

    func asFoodItem() -> FoodItem {
        FoodItem(
            id: FoodItemIdentifier(UUID().uuidString),
            name: name,
            brandName: nil,
            flavour: nil,
            country: nil,
            calories: .init(value: Double(calories), unit: "kcal"),
            protein: .init(value: Double(protein), unit: "g"),
            carbohydrates: .init(value: Double(carbs), unit: "g"),
            fat: .init(value: Double(fat), unit: "g"),
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
            servingQuantity: .init(
                value: servingAmount,
                unit: servingAmountUnit
            ),
            ingredients: nil,
            category: .aiGenerated,
            isVerified: false
        )
  }
}
