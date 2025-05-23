//
//  DetectedFood+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-23.
//

import Foundation
import BloomModel

extension DetectedFood.FoodItem {

  func asServing() -> EstimateFoodCaloriesResponse.Serving {
    .init(
      servings: servingCount,
      item: asFoodItem()
    )
  }

  func asFoodItem() -> BloomModel.FoodItem {
    BloomModel.FoodItem(
      id: FoodItemIdentifier(UUID().uuidString),
      name: name,
      brandName: brandName,
      flavour: brandName,
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
      servingQuantity: nil,
      ingredients: nil,
      category: .aiGenerated,
      isVerified: false
    )
  }
}
