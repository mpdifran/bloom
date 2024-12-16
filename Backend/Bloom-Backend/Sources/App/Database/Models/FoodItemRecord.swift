//
//  FoodItemRecord.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor
import Fluent

final class FoodItemRecord: Model, @unchecked Sendable {
  static let schema = "food_item_records"

  @ID(custom: "id", generatedBy: .user)
  var id: String?

  @Field(key: "name")
  var name: String

  @Enum(key: "state")
  var state: State

  @Field(key: "brand_name")
  var brandName: String?

  @Field(key: "flavour")
  var flavour: String?

  @Enum(key: "category")
  var category: Category

  @Field(key: "barcode")
  var barcode: String?

  @Field(key: "nutrition_label_image")
  var nutritionLabelImage: String?

  @Field(key: "packaging_image")
  var packagingImage: String?

  @Field(key: "ingredients")
  var ingredients: String?

  @Enum(key: "country")
  var country: Country

  @Field(key: "calories")
  var calories: Double?

  @Field(key: "protein")
  var protein: Double?

  @Field(key: "carbohydrates")
  var carbohydrates: Double?

  @Field(key: "fat")
  var fat: Double?

  @Field(key: "saturated_fat")
  var saturatedFat: Double?

  @Field(key: "trans_fat")
  var transFat: Double?

  @Field(key: "polyunsaturated_fat")
  var polyunsaturatedFat: Double?

  @Field(key: "monounsaturated_fat")
  var monounsaturatedFat: Double?

  @Field(key: "fiber")
  var fiber: Double?

  @Field(key: "sugar")
  var sugar: Double?

  @Field(key: "cholesterol")
  var cholesterol: Double?

  @Field(key: "sodium")
  var sodium: Double?

  @Field(key: "calcium")
  var calcium: Double?

  @Field(key: "iron")
  var iron: Double?

  @Field(key: "potassium")
  var potassium: Double?

  @Field(key: "magnesium")
  var magnesium: Double?

  @Field(key: "zinc")
  var zinc: Double?

  @Field(key: "vitamin_a")
  var vitaminA: Double?

  @Field(key: "vitamin_b6")
  var vitaminB6: Double?

  @Field(key: "vitamin_b12")
  var vitaminB12: Double?

  @Field(key: "vitamin_c")
  var vitaminC: Double?

  @Field(key: "vitamin_d")
  var vitaminD: Double?

  @Field(key: "vitamin_e")
  var vitaminE: Double?

  @Field(key: "serving_name")
  var servingName: String?

  @Field(key: "serving_value")
  var servingValue: Double?

  @Field(key: "serving_unit")
  var servingUnit: String?

  @Field(key: "downvote_count")
  var downvoteCount: Int?

  @Field(key: "source")
  var source: String?

  @Field(key: "notes")
  var notes: String?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() { }

  init(
    id: String,
    name: String,
    country: Country,
    category: Category,
    source: String
  ) {
    // Make sure every property is set to something so the app doesn't crash when converting to the network food item.
    self.id = id
    self.name = name
    self.state = .unverified
    self.brandName = nil
    self.flavour = nil
    self.category = category
    self.barcode = nil
    self.nutritionLabelImage = nil
    self.packagingImage = nil
    self.ingredients = nil
    self.country = country
    self.calories = nil
    self.protein = nil
    self.carbohydrates = nil
    self.fat = nil
    self.saturatedFat = nil
    self.transFat = nil
    self.polyunsaturatedFat = nil
    self.monounsaturatedFat = nil
    self.fiber = nil
    self.sugar = nil
    self.cholesterol = nil
    self.sodium = nil
    self.calcium = nil
    self.iron = nil
    self.potassium = nil
    self.magnesium = nil
    self.zinc = nil
    self.vitaminA = nil
    self.vitaminB6 = nil
    self.vitaminB12 = nil
    self.vitaminC = nil
    self.vitaminD = nil
    self.vitaminE = nil
    self.servingName = nil
    self.servingValue = nil
    self.servingUnit = nil
    self.downvoteCount = nil
    self.source = source
    self.notes = nil
  }
}

extension FoodItemRecord {
  enum State: String, Codable, FluentEnum {
    static let schema = "state"

    case needsAIProcessing
    case unverified
    case needsMoreInfo
    case verified
  }

  enum Category: String, Codable, FluentEnum {
    static let schema = "category"

    case generic
    case fastfood
    case restaurant
    case branded
  }

  enum Country: String, Codable, FluentEnum {
    static let schema = "country"
    
    case canada
    case usa
  }
}
