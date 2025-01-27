//
//  FoodItemIssue.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-01-27.
//

import Foundation
import AppFoundations

/// A collection of issues with a food item. If a field is nil, that means it shouldn't be changed.
public struct FoodItemIssue: Codable, Sendable {

  /// What the name of the item should be.
  public let name: String?

  /// What the brand name of the item should be.
  public let brandName: String?

  /// What the flavour of the item should be.
  public let flavour: String?

  public let calories: Double?
  public let protein: Double?
  public let carbohydrates: Double?
  public let fat: Double?
  public let saturatedFat: Double?
  public let transFat: Double?
  public let polyunsaturatedFat: Double?
  public let monounsaturatedFat: Double?
  public let fiber: Double?
  public let sugar: Double?
  public let cholesterol: Double?
  public let sodium: Double?
  public let calcium: Double?
  public let iron: Double?
  public let potassium: Double?
  public let magnesium: Double?
  public let zinc: Double?
  public let vitaminA: Double?
  public let vitaminB6: Double?
  public let vitaminB12: Double?
  public let vitaminC: Double?
  public let vitaminD: Double?
  public let vitaminE: Double?

  /// The name for a single serving. For "1 breast (100 g)", this would be "1 breast".
  public let servingName: String?
  /// The measured amount in a serving. For "1 breast (100 g)", this would be 100.
  public let servingValue: Double?
  /// The unit for the measured amount in a serving. For "1 breast (100 g)", this would be "g".
  public let servingUnit: String?

  public let ingredients: String?
  public let barcode: String?
  public let nutritionLabelImage: ImageFile?
  public let packagingImage: ImageFile?
  public let notes: String?

  public let foodItemID: FoodItemIdentifier

  public init(
    name: String?,
    brandName: String?,
    flavour: String?,
    calories: Double?,
    protein: Double?,
    carbohydrates: Double?,
    fat: Double?,
    saturatedFat: Double?,
    transFat: Double?,
    polyunsaturatedFat: Double?,
    monounsaturatedFat: Double?,
    fiber: Double?,
    sugar: Double?,
    cholesterol: Double?,
    sodium: Double?,
    calcium: Double?,
    iron: Double?,
    potassium: Double?,
    magnesium: Double?,
    zinc: Double?,
    vitaminA: Double?,
    vitaminB6: Double?,
    vitaminB12: Double?,
    vitaminC: Double?,
    vitaminD: Double?,
    vitaminE: Double?,
    servingName: String?,
    servingValue: Double?,
    servingUnit: String?,
    ingredients: String?,
    barcode: String?,
    nutritionLabelImage: ImageFile?,
    packagingImage: ImageFile?,
    notes: String?,
    foodItemID: FoodItemIdentifier
  ) {
    self.name = name
    self.brandName = brandName
    self.flavour = flavour
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
    self.servingValue = servingValue
    self.servingUnit = servingUnit
    self.ingredients = ingredients
    self.barcode = barcode
    self.nutritionLabelImage = nutritionLabelImage
    self.packagingImage = packagingImage
    self.notes = notes
    self.foodItemID = foodItemID
  }
}
