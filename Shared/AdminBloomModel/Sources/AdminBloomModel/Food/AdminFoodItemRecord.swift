//
//  AdminFoodItemRecord.swift
//  bloom-model
//
//  Created by Zach Radford on 2024-12-01.
//

import BloomModel
import Foundation

public struct AdminFoodItemRecord: Codable, Identifiable, Sendable, Hashable {
  /// ID is the only field required to initialize, this is how we identify in the DB for updates.
  public let id: FoodItemIdentifier
  public var name: String?
  public var state: State
  public var brandName: String?
  public var flavour: String?
  public var category: Category?
  public var barcode: String?
  public var nutritionLabelImage: URL?
  public var packagingImage: URL?
  public var ingredients: String?
  public var country: FoodItem.Country?
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
  public var downvoteCount: Int?
  public var source: String?
  public var notes: String?
  /// Read-only.
  public var createdAt: Date?
  /// Read-only.
  public var updatedAt: Date?

  public init(id: FoodItemIdentifier, state: State = .unverified) {
    self.id = id
    self.state = state
  }

  public init(
    id: FoodItemIdentifier,
    name: String?,
    state: State,
    brandName: String?,
    flavour: String?,
    category: Category?,
    barcode: String?,
    ingredients: String?,
    country: FoodItem.Country?,
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
    downvoteCount: Int?,
    source: String?,
    notes: String?,
    createdAt: Date?,
    updatedAt: Date?
  ) {
    self.id = id
    self.name = name
    self.state = state
    self.brandName = brandName
    self.flavour = flavour
    self.category = category
    self.barcode = barcode
    self.ingredients = ingredients
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
    self.servingValue = servingValue
    self.servingUnit = servingUnit
    self.downvoteCount = downvoteCount
    self.source = source
    self.notes = notes
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public extension AdminFoodItemRecord {
  enum State: String, Codable, Sendable, CaseIterable, Identifiable {
    public var id: Self { self }

    case needsAIProcessing
    case unverified
    case needsMoreInfo
    case verified

    public var name: String {
      switch self {
      case .needsAIProcessing:
        "Needs AI Processing"
      case .unverified:
        "Unverified"
      case .needsMoreInfo:
        "Needs More Info"
      case .verified:
        "Verified"
      }
    }
  }
}

public extension AdminFoodItemRecord {
  enum Category: String, Codable, Sendable, CaseIterable {
    case generic
    case fastfood
    case restaurant
    case branded
  }
}
