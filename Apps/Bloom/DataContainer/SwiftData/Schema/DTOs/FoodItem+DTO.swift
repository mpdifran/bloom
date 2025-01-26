//
//  FoodItem+DTO.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
import SwiftData

public struct FoodItemDTO: Sendable {
  public let persistentID: PersistentIdentifier
  public let id: String
  public let name: String
  public let brandName: String
  public let flavour: String

  public let rawCountry: String?

  public let calories: Double
  public let protein: Double
  public let carbohydrates: Double
  public let fat: Double

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

  public let servingName: String?
  public let servingUnitString: String?
  public let servingValue: Double?
  public let ingredients: String?
  public let category: FoodItemRecord.Category?
  public let isVerified: Bool

  public init(
    persistentID: PersistentIdentifier,
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
    category: FoodItemRecord.Category?,
    isVerified: Bool
  ) {
    self.persistentID = persistentID
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

public extension FoodItemRecord {

  func asDTO() -> FoodItemDTO {
    FoodItemDTO(
      persistentID: persistentModelID,
      id: id,
      name: name,
      brandName: brandName,
      flavour: flavour,
      rawCountry: rawCountry,
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
      servingUnitString: servingUnitString,
      servingValue: servingValue,
      ingredients: ingredients,
      category: category,
      isVerified: isVerified
    )
  }
}
