//
//  FoodItemRecordV6.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-19.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV6 {
  @Model
  public final class FoodItemRecord: Identifiable, Hashable {
    public var id: String = ""
    public var name: String = ""
    public var brandName: String = ""
    public var flavour: String = ""

    public var rawCountry: String?

    public var calories: Double = 0.0
    public var protein: Double = 0.0
    public var carbohydrates: Double = 0.0
    public var fat: Double = 0.0

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
    public var servingUnitString: String?
    public var servingValue: Double?
    public var ingredients: String?
    public var category: Category?
    public var isVerified: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \FoodItemLog.foodItem)
    public var logs: [FoodItemLog]?

    @Relationship(inverse: \FoodItemServing.foodItem)
    public var servings: [FoodItemServing]? = []

    @Relationship(inverse: \MealItemRecord.foodItem)
    public var mealItems: [MealItemRecord]? = []

    public init(
      id: String,
      name: String,
      brandName: String,
      flavour: String,
      rawCountry: String?,
      calories: Double,
      protein: Double,
      carbohydrates: Double,
      fat: Double,
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
      servingUnitString: String?,
      servingValue: Double?,
      ingredients: String?,
      category: Category?,
      isVerified: Bool
    ) {
      self.id = id
      self.name = name
      self.brandName = brandName
      self.flavour = flavour
      self.rawCountry = rawCountry
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
      self.servingUnitString = servingUnitString
      self.servingValue = servingValue
      self.ingredients = ingredients
      self.category = category
      self.isVerified = isVerified
    }
  }
}

public extension SchemaV6.FoodItemRecord {
  enum Category: String, Hashable, Codable, Sendable {
    case generic
    case fastfood
    case restaurant
    case branded
    case aiGenerated
  }
}
