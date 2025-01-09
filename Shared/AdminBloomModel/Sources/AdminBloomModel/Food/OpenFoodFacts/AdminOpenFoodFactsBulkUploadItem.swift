//
//  AdminOpenFoodFactsBulkUploadItem.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-09.
//

import Foundation

public struct AdminOpenFoodFactsBulkUploadItem: Codable, Sendable {
  public let productName: String?
  public let brand: String?
  public let barcode: String
  public let countries: [String]
  public let ingredients: String?
  public let servingName: String
  public let servingQuantity: Double
  public let servingUnit: String
  public let packagingImageURL: URL?
  public let nutrientsImageURL: URL?
  public let energy: Double // kcal
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

  public init(
    productName: String?,
    brand: String?,
    barcode: String,
    countries: [String],
    ingredients: String?,
    servingName: String,
    servingQuantity: Double,
    servingUnit: String,
    packagingImageURL: URL?,
    nutrientsImageURL: URL?,
    energy: Double,
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
    vitaminE: Double?
  ) {
    self.productName = productName
    self.brand = brand
    self.barcode = barcode
    self.countries = countries
    self.ingredients = ingredients
    self.servingName = servingName
    self.servingQuantity = servingQuantity
    self.servingUnit = servingUnit
    self.packagingImageURL = packagingImageURL
    self.nutrientsImageURL = nutrientsImageURL
    self.energy = energy
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
  }
}
