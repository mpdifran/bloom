//
//  FoodItemIssueReportState.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-02.
//

import Foundation
import HealthKit
import BloomModel

struct FoodItemIssueReportState {
  var name: String = ""
  var brandName: String = ""
  var flavour: String = ""
  var calories: Double = 0
  var protein: Double = 0
  var carbohydrates: Double = 0
  var fat: Double = 0
  var saturatedFat: Double = 0
  var transFat: Double = 0
  var polyunsaturatedFat: Double = 0
  var monounsaturatedFat: Double = 0
  var fiber: Double = 0
  var sugar: Double = 0
  var cholesterol: Double = 0
  var sodium: Double = 0
  var calcium: Double = 0
  var iron: Double = 0
  var potassium: Double = 0
  var magnesium: Double = 0
  var zinc: Double = 0
  var vitaminA: Double = 0
  var vitaminB6: Double = 0
  var vitaminB12: Double = 0
  var vitaminC: Double = 0
  var vitaminD: Double = 0
  var vitaminE: Double = 0
  var servingName: String = ""
  var servingValue: Double = 0
  var servingUnit: String = ""
  var ingredients: String = ""
  var barcode: String = ""
  var notes: String = ""

  init(foodItem: FoodItem) {
    self.name = foodItem.name
    self.brandName = foodItem.brandName ?? ""
    self.flavour = foodItem.flavour ?? ""
    self.calories = foodItem.calories?.value ?? -1
    self.protein = foodItem.protein?.value ?? -1
    self.carbohydrates = foodItem.carbohydrates?.value ?? -1
    self.fat = foodItem.fat?.value ?? -1
    self.saturatedFat = foodItem.saturatedFat?.value ?? -1
    self.transFat = foodItem.transFat?.value ?? -1
    self.polyunsaturatedFat = foodItem.polyunsaturatedFat?.value ?? -1
    self.monounsaturatedFat = foodItem.monounsaturatedFat?.value ?? -1
    self.fiber = foodItem.fiber?.value ?? -1
    self.sugar = foodItem.sugar?.value ?? -1
    self.cholesterol = foodItem.cholesterol?.value ?? -1
    self.sodium = foodItem.sodium?.hkQuantity.doubleValue(for: .gramUnit(with: .milli)) ?? -1
    self.calcium = foodItem.calcium?.hkQuantity.doubleValue(for: .gramUnit(with: .milli)) ?? -1
    self.iron = foodItem.iron?.hkQuantity.doubleValue(for: .gramUnit(with: .milli)) ?? -1
    self.potassium = foodItem.potassium?.hkQuantity.doubleValue(for: .gramUnit(with: .milli)) ?? -1
    self.magnesium = foodItem.magnesium?.hkQuantity.doubleValue(for: .gramUnit(with: .milli)) ?? -1
    self.zinc = foodItem.zinc?.hkQuantity.doubleValue(for: .gramUnit(with: .milli)) ?? -1
    self.vitaminA = foodItem.vitaminA?.hkQuantity.doubleValue(for: .gramUnit(with: .micro)) ?? -1
    self.vitaminB6 = foodItem.vitaminB6?.hkQuantity.doubleValue(for: .gramUnit(with: .micro)) ?? -1
    self.vitaminB12 = foodItem.vitaminB12?.hkQuantity.doubleValue(for: .gramUnit(with: .micro)) ?? -1
    self.vitaminC = foodItem.vitaminC?.hkQuantity.doubleValue(for: .gramUnit(with: .micro)) ?? -1
    self.vitaminD = foodItem.vitaminD?.hkQuantity.doubleValue(for: .gramUnit(with: .micro)) ?? -1
    self.vitaminE = foodItem.vitaminE?.hkQuantity.doubleValue(for: .gramUnit(with: .micro)) ?? -1
    self.servingName = foodItem.servingName ?? ""
    self.servingValue = foodItem.servingQuantity?.value ?? -1
    self.servingUnit = foodItem.servingQuantity?.unit ?? ""
    self.ingredients = foodItem.ingredients ?? ""
  }
}
