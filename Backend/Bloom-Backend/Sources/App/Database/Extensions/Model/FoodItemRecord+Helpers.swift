//
//  FoodItemRecord+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-12.
//

import Foundation
import BloomModel

extension FoodItemRecord {

  func asFoodItem() -> FoodItem? {
    guard let id = id else { return nil }

    let servingQuantity: FoodItem.Quantity?
    if let servingValue, let servingUnit {
      servingQuantity = .init(value: servingValue, unit: servingUnit)
    } else {
      servingQuantity = nil
    }

    return FoodItem(
      id: FoodItemIdentifier(id),
      name: name,
      brandName: brandName,
      flavour: flavour,
      country: country.asCountry(),
      calories: calories.map({ .init(value: $0, unit: "kcal")}),
      protein: protein.map({ .init(value: $0, unit: "g")}),
      carbohydrates: carbohydrates.map({ .init(value: $0, unit: "g")}),
      fat: fat.map({ .init(value: $0, unit: "g")}),
      saturatedFat: saturatedFat.map({ .init(value: $0, unit: "g") }),
      transFat: transFat.map({ .init(value: $0, unit: "g") }),
      polyunsaturatedFat: polyunsaturatedFat.map({ .init(value: $0, unit: "g") }),
      monounsaturatedFat: monounsaturatedFat.map({ .init(value: $0, unit: "g") }),
      fiber: fiber.map({ .init(value: $0, unit: "g") }),
      sugar: sugar.map({ .init(value: $0, unit: "g") }),
      cholesterol: cholesterol.map({ .init(value: $0, unit: "mg") }),
      sodium: sodium.map({ .init(value: $0, unit: "mg") }),
      calcium: calcium.map({ .init(value: $0, unit: "mg") }),
      iron: iron.map({ .init(value: $0, unit: "mg") }),
      potassium: potassium.map({ .init(value: $0, unit: "mg") }),
      magnesium: magnesium.map({ .init(value: $0, unit: "mg") }),
      zinc: zinc.map({ .init(value: $0, unit: "mg") }),
      vitaminA: vitaminA.map({ .init(value: $0, unit: "mg") }),
      vitaminB6: vitaminB6.map({ .init(value: $0, unit: "mg") }),
      vitaminB12: vitaminB12.map({ .init(value: $0, unit: "mg") }),
      vitaminC: vitaminC.map({ .init(value: $0, unit: "mg") }),
      vitaminD: vitaminD.map({ .init(value: $0, unit: "mg") }),
      vitaminE: vitaminE.map({ .init(value: $0, unit: "mg") }),
      servingName: servingName,
      servingQuantity: servingQuantity,
      ingredients: nil,
      category: category.asCategory(),
      isVerified: state == .verified
    )
  }
}

extension FoodItemRecord {
  func asAdminFoodItemRecord() -> AdminFoodItemRecord? {
    guard let id = id else { return nil }

    return .init(
      id: FoodItemIdentifier(id),
      name: name,
      state: state.asState(),
      brandName: brandName,
      flavour: flavour,
      category: category.asCategory(),
      barcode: barcode,
      nutritionLabelImage: nutritionLabelImage,
      packagingImage: packagingImage,
      ingredients: ingredients,
      country: country.asCountry(),
      calories: calories,
      protein: protein,
      carbohydrates: carbohydrates,
      fat: fat,
      saturatedFat: saturatedFat,
      transFat: transFat,
      polyunsaturatedFat: polyunsaturatedFat,
      monounsaturatedFat: monounsaturatedFat,
      fiber: fiber,
      sugar: sugar,
      cholesterol: cholesterol,
      sodium: sodium,
      calcium: calcium,
      iron: iron,
      potassium: potassium,
      magnesium: magnesium,
      zinc: zinc,
      vitaminA: vitaminA,
      vitaminB6: vitaminB6,
      vitaminB12: vitaminB12,
      vitaminC: vitaminC,
      vitaminD: vitaminD,
      vitaminE: vitaminE,
      servingName: servingName,
      servingValue: servingValue,
      servingUnit: servingUnit,
      downvoteCount: downvoteCount,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

extension FoodItemRecord.Category {

  func asCategory() -> FoodItem.Category {
    switch self {
    case .generic: .generic
    case .fastfood: .fastfood
    case .restaurant: .restaurant
    case .branded: .branded
    }
  }
}

extension FoodItemRecord.State {
  func asState() -> AdminFoodItemRecord.State {
    switch self {
    case .unverified: .unverified
    case .verified: .verified
    }
  }
}

extension FoodItemRecord.Country {
  func asCountry() -> FoodItem.Country {
    switch self {
    case .canada: .canada
    case .usa: .usa
    }
  }
}
