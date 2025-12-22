//
//  AdminFoodItemIssueReport.swift
//  AdminBloomModel
//
//  Created by Claude on 2025-12-22.
//

import BloomModel
import Foundation

public struct AdminFoodItemIssueReport: Codable, Sendable, Identifiable, Hashable {
  public let id: String
  public let foodItemRecordID: FoodItemIdentifier

  // User info
  public let userName: String?
  public let userID: String?

  // Suggested changes (all optional - nil means no change suggested)
  public var name: String?
  public var brandName: String?
  public var flavour: String?
  public var nutritionLabelImage: URL?
  public var packagingImage: URL?
  public var ingredients: String?
  public var calories: Double?
  public var protein: Double?
  public var carbohydrates: Double?
  public var fat: Double?
  public var saturatedFat: Double?
  public var transFat: Double?
  public var polyunsaturatedFat: Double?
  public var monounsaturatedFat: Double?
  public var fiber: Double?
  public var sugar: Double?
  public var cholesterol: Double?
  public var sodium: Double?
  public var calcium: Double?
  public var iron: Double?
  public var potassium: Double?
  public var magnesium: Double?
  public var zinc: Double?
  public var vitaminA: Double?
  public var vitaminB6: Double?
  public var vitaminB12: Double?
  public var vitaminC: Double?
  public var vitaminD: Double?
  public var vitaminE: Double?
  public var servingName: String?
  public var servingValue: Double?
  public var servingUnit: String?
  public var notes: String?

  public let createdAt: Date?

  public init(
    id: String,
    foodItemRecordID: FoodItemIdentifier,
    userName: String?,
    userID: String?,
    name: String?,
    brandName: String?,
    flavour: String?,
    nutritionLabelImage: URL?,
    packagingImage: URL?,
    ingredients: String?,
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
    notes: String?,
    createdAt: Date?
  ) {
    self.id = id
    self.foodItemRecordID = foodItemRecordID
    self.userName = userName
    self.userID = userID
    self.name = name
    self.brandName = brandName
    self.flavour = flavour
    self.nutritionLabelImage = nutritionLabelImage
    self.packagingImage = packagingImage
    self.ingredients = ingredients
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
    self.notes = notes
    self.createdAt = createdAt
  }
}
