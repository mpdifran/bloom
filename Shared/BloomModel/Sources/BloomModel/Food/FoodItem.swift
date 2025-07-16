//
//  Food.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation
import AppFoundations

public final class FoodItemIdentifier: Identifier, Codable, @unchecked Sendable { }

public struct FoodItem: Codable, Identifiable, Sendable, Hashable {
  public let id: FoodItemIdentifier

  public let name: String
  public let brandName: String?
  public let flavour: String?

  public let country: String?

  public let calories: Quantity?
  public let protein: Quantity?
  public let carbohydrates: Quantity?
  public let fat: Quantity?

  public let saturatedFat: Quantity?
  public let transFat: Quantity?
  public let polyunsaturatedFat: Quantity?
  public let monounsaturatedFat: Quantity?
  public let fiber: Quantity?
  public let sugar: Quantity?
  public let cholesterol: Quantity?
  public let sodium: Quantity?
  public let calcium: Quantity?
  public let iron: Quantity?
  public let potassium: Quantity?
  public let magnesium: Quantity?
  public let zinc: Quantity?
  public let vitaminA: Quantity?
  public let vitaminB6: Quantity?
  public let vitaminB12: Quantity?
  public let vitaminC: Quantity?
  public let vitaminD: Quantity?
  public let vitaminE: Quantity?

  /// The serving name is what you might see on a nutrition label (e.g. 1 breast, 1 package, 24 chips)
  public let servingName: String?

  /// The serving quantity is some numerical breakdown of the serving name, such as
  /// {
  ///    unit: "g" (like grams),
  ///    value: 100
  /// }
  public let servingQuantity: Quantity?
  public let ingredients: String?
  public let category: Category
  public let isVerified: Bool

  public init(
    id: FoodItemIdentifier,
    name: String,
    brandName: String?,
    flavour: String?,
    country: String?,
    calories: Quantity?,
    protein: Quantity?,
    carbohydrates: Quantity?,
    fat: Quantity?,
    saturatedFat: Quantity?,
    transFat: Quantity?,
    polyunsaturatedFat: Quantity?,
    monounsaturatedFat: Quantity?,
    fiber: Quantity?,
    sugar: Quantity?,
    cholesterol: Quantity?,
    sodium: Quantity?,
    calcium: Quantity?,
    iron: Quantity?,
    potassium: Quantity?,
    magnesium: Quantity?,
    zinc: Quantity?,
    vitaminA: Quantity?,
    vitaminB6: Quantity?,
    vitaminB12: Quantity?,
    vitaminC: Quantity?,
    vitaminD: Quantity?,
    vitaminE: Quantity?,
    servingName: String?,
    servingQuantity: Quantity?,
    ingredients: String?,
    category: Category,
    isVerified: Bool
  ) {
    self.id = id
    self.name = name
    self.brandName = brandName
    self.flavour = flavour
    self.country = country
    self.calories = calories
    self.protein = protein
    self.carbohydrates = carbohydrates
    self.fat = fat
    self.saturatedFat = saturatedFat
    self.transFat = transFat
    self.polyunsaturatedFat = polyunsaturatedFat
    self.monounsaturatedFat = monounsaturatedFat
    self.fiber = fiber
    self.sugar = sugar
    self.cholesterol = cholesterol
    self.sodium = sodium
    self.calcium = calcium
    self.iron = iron
    self.potassium = potassium
    self.magnesium = magnesium
    self.zinc = zinc
    self.vitaminA = vitaminA
    self.vitaminB6 = vitaminB6
    self.vitaminB12 = vitaminB12
    self.vitaminC = vitaminC
    self.vitaminD = vitaminD
    self.vitaminE = vitaminE
    self.servingName = servingName
    self.servingQuantity = servingQuantity
    self.ingredients = ingredients
    self.category = category
    self.isVerified = isVerified
  }
}

public extension FoodItem {
  struct Quantity: Codable, Sendable, Hashable {
    public let value: Double
    public let unit: String

    public init(
      value: Double,
      unit: String
    ) {
      self.value = value
      self.unit = unit
    }
  }
}

public extension FoodItem {
  enum Category: String, Codable, Sendable, CaseIterable, Equatable {
    case generic
    case fastfood
    case restaurant
    case branded
    case aiGenerated
  }
}


public extension FoodItem {

  var displayServing: String {
    var result = ""

    if let name = servingName {
      result = name
    }

    if let quantity = servingQuantity {
      result += " (\(quantity.value.formatted()) \(quantity.unit))"
    }

    return result
  }
}
