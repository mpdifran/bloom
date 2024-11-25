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
        let servingAmount: Int
        let servingCount: Double
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
            calories: .init(value: Double(calories), unit: "kcal"),
            protein: .init(value: Double(protein), unit: "g"),
            carbohydrates: .init(value: Double(carbs), unit: "g"),
            fat: .init(value: Double(fat), unit: "g"),
            servingName: servingName,
            servingQuantity: FoodItem.Quantity(
                value: Double(servingAmount),
                unit: servingAmountUnit),
            ingredients: nil,
            category: .aiGenerated,
            isVerified: false
        )
  }
}
