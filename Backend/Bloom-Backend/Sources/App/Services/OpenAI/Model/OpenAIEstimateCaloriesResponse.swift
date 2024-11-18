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
    }

    struct Quantity: Codable {
        let value: Double
        let unit: String
    }
}

extension OpenAIEstimateCaloriesResponse.Item {

    func asFoodItem() -> FoodItem {
        let nutrients: [FoodItem.Nutrient] = [
            .init(kind: .calories, quantity: .init(value: Double(calories), unit: "calories")),
            .init(kind: .fat, quantity: .init(value: Double(fat), unit: "grams")),
            .init(kind: .carbohydrates, quantity: .init(value: Double(carbs), unit: "grams")),
            .init(kind: .protein, quantity: .init(value: Double(protein), unit: "grams"))
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
