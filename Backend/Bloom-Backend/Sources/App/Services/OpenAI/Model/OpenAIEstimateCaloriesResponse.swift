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
        let servingAmount: Int
        let calories: Int
        let fat: Int
        let carbs: Int
        let protein: Int
        let totalCalories: Int
        let totalFat: Int
        let totalCarbs: Int
        let totalProtein: Int
    }

    struct Quantity: Codable {
        let value: Double
        let unit: String
    }
}

extension OpenAIEstimateCaloriesResponse.Item {

    func asFoodItem() -> FoodItem {
      let nutrients: [FoodItem.Nutrient] = [
        .init(kind: .calories, quantity: .init(value: Double(totalCalories), unit: "calories")),
        .init(kind: .fat, quantity: .init(value: Double(totalFat), unit: "grams")),
        .init(kind: .carbohydrates, quantity: .init(value: Double(totalCarbs), unit: "grams")),
        .init(kind: .protein, quantity: .init(value: Double(totalProtein), unit: "grams"))
      ]
      return FoodItem(id: FoodItemIdentifier(UUID().uuidString),
                      name: name,
                      brandName: nil,
                      nutrients: nutrients,
                      servingName: servingName,
                      servingQuantity: FoodItem.Quantity(
                        value: Double(servingAmount),
                        unit: servingName),
                      ingredients: nil)
  }
}
