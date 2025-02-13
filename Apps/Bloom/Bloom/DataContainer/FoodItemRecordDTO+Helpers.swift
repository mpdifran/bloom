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
      quantity = FoodItem.Quantity(
        value: servingValue,
        unit: servingUnitString
      )
    } else {
      quantity = nil
    }

    return FoodItem(
      id: FoodItemIdentifier(id),
      name: name,
      brandName: brandName,
      flavour: flavour,
      country: nil, // TODO: Fill this in
      calories: FoodItem.Quantity(value: calories, unit: "kcal"),
      protein: FoodItem.Quantity(value: protein, unit: "g"),
      carbohydrates: FoodItem.Quantity(value: carbohydrates, unit: "g"),
      fat: FoodItem.Quantity(value: fat, unit: "g"),
      saturatedFat: saturatedFat.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      transFat: transFat.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      polyunsaturatedFat: polyunsaturatedFat.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      monounsaturatedFat: monounsaturatedFat.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      fiber: fiber.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      sugar: sugar.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      cholesterol: cholesterol.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      sodium: sodium.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      calcium: calcium.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      iron: iron.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      potassium: potassium.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      magnesium: magnesium.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      zinc: zinc.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminA: vitaminA.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminB6: vitaminB6.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminB12: vitaminB12.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminC: vitaminC.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminD: vitaminD.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminE: vitaminE.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
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
