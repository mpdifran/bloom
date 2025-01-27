//
//  FoodItemIssueReport.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-26.
//

import Foundation
import Vapor
import Fluent

final class FoodItemIssueReport: Model, @unchecked Sendable {
  static let schema = "food_item_issue_reports"

  @ID(custom: "id", generatedBy: .user)
  var id: String?

  @Field(key: "name")
  var name: String?

  @Field(key: "brand_name")
  var brandName: String?

  @Field(key: "flavour")
  var flavour: String?

  @Field(key: "barcode")
  var barcode: String?

  @Field(key: "nutrition_label_image")
  var nutritionLabelImage: String?

  @Field(key: "packaging_image")
  var packagingImage: String?

  @Field(key: "ingredients")
  var ingredients: String?

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

  @Field(key: "notes")
  var notes: String?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  @Parent(key: "user_id")
  var user: User

  init() { }

  init(
    id: String,
    name: String,
    userID: User.IDValue
  ) {
    // Make sure every property is set to something so the app doesn't crash when converting to the network food item.
    self.id = id
    self.name = name
    self.brandName = nil
    self.flavour = nil
    self.barcode = nil
    self.nutritionLabelImage = nil
    self.packagingImage = nil
    self.ingredients = nil
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
    self.notes = nil
    self.$user.id = userID
  }

  init(
    id: String,
    name: String,
    state: FoodItemRecord.State,
    brandName: String?,
    flavour: String?,
    category: FoodItemRecord.Category,
    barcode: String?,
    nutritionLabelImage: String?,
    packagingImage: String?,
    ingredients: String?,
    country: FoodItemRecord.Country,
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
    updatedAt: Date?,
    userID: User.IDValue
  ) {
    self.id = id
    self.name = name
    self.brandName = brandName
    self.flavour = flavour
    self.barcode = barcode
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
    self.updatedAt = updatedAt
    self.$user.id = userID
  }
}
