//
//  OpenAIEstimateCaloriesResponse.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-14.
//

import Foundation
import BloomModel

struct OpenAIEstimateCaloriesResponse: Codable {
  let name: String
  let foodItems: [Item]
  let optionalFoodItems: [Item]?
}

extension OpenAIEstimateCaloriesResponse {
  struct Item: Codable, Equatable, Sendable {
    let name: String
    let brandName: String?
    let flavour: String?
    let servingName: String
    let servingValue: Quantity
    let servingCount: Double
    let calories: Quantity
    let fat: Quantity?
    let carbohydrates: Quantity?
    let protein: Quantity?
    let saturatedFat: Quantity?
    let transFat: Quantity?
    let polyunsaturatedFat: Quantity?
    let monounsaturatedFat: Quantity?
    let fiber: Quantity?
    let sugar: Quantity?
    let cholesterol: Quantity?
    let sodium: Quantity?
    let calcium: Quantity?
    let iron: Quantity?
    let potassium: Quantity?
    let magnesium: Quantity?
    let zinc: Quantity?
    let vitaminA: Quantity?
    let vitaminB6: Quantity?
    let vitaminB12: Quantity?
    let vitaminC: Quantity?
    let vitaminD: Quantity?
    let vitaminE: Quantity?
  }

  struct Quantity: Codable, Equatable, Sendable {
    let value: Double
    let unit: String
  }
}

extension OpenAIEstimateCaloriesResponse.Item {

  func asServing() -> EstimateFoodCaloriesResponse.Serving {
    .init(
      servings: servingCount,
      item: asFoodItem()
    )
  }

  func asFoodItem() -> FoodItem {
    FoodItem(
      id: FoodItemIdentifier(UUID().uuidString),
      name: name,
      brandName: brandName,
      flavour: flavour,
      country: nil,
      calories: .init(value: calories.value, unit: calories.unit),
      protein: protein.map({ .init(value: $0.value, unit: $0.unit) }),
      carbohydrates: carbohydrates.map({ .init(value: $0.value, unit: $0.unit) }),
      fat: fat.map({ .init(value: $0.value, unit: $0.unit) }),
      saturatedFat: saturatedFat.map({ .init(value: $0.value, unit: $0.unit) }),
      transFat: transFat.map({ .init(value: $0.value, unit: $0.unit) }),
      polyunsaturatedFat: polyunsaturatedFat.map({ .init(value: $0.value, unit: $0.unit) }),
      monounsaturatedFat: monounsaturatedFat.map({ .init(value: $0.value, unit: $0.unit) }),
      fiber: fiber.map({ .init(value: $0.value, unit: $0.unit) }),
      sugar: sugar.map({ .init(value: $0.value, unit: $0.unit) }),
      cholesterol: cholesterol.map({ .init(value: $0.value, unit: $0.unit) }),
      sodium: sodium.map({ .init(value: $0.value, unit: $0.unit) }),
      calcium: calcium.map({ .init(value: $0.value, unit: $0.unit) }),
      iron: iron.map({ .init(value: $0.value, unit: $0.unit) }),
      potassium: potassium.map({ .init(value: $0.value, unit: $0.unit) }),
      magnesium: magnesium.map({ .init(value: $0.value, unit: $0.unit) }),
      zinc: zinc.map({ .init(value: $0.value, unit: $0.unit) }),
      vitaminA: vitaminA.map({ .init(value: $0.value, unit: $0.unit) }),
      vitaminB6: vitaminB6.map({ .init(value: $0.value, unit: $0.unit) }),
      vitaminB12: vitaminB12.map({ .init(value: $0.value, unit: $0.unit) }),
      vitaminC: vitaminC.map({ .init(value: $0.value, unit: $0.unit) }),
      vitaminD: vitaminD.map({ .init(value: $0.value, unit: $0.unit) }),
      vitaminE: vitaminE.map({ .init(value: $0.value, unit: $0.unit) }),
      servingName: servingName,
      servingQuantity: .init(
        value: servingValue.value,
        unit: servingValue.unit
      ),
      ingredients: nil,
      category: .aiGenerated,
      isVerified: false
    )
  }
}
