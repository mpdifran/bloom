//
//  FoodItemNutrient.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-24.
//

import DataContainer
import Foundation
import HealthKit

// MARK: - FoodItemNutrient

/// Making the logged health types opt-in.
/// We can leverage allCases to make logging more generic.
enum FoodItemNutrient: CaseIterable {
  case calories
  case protein
  case carbohydrates
  case fat
  case sugar
  case saturatedFat
  case polyunsaturatedFat
  case monounsaturatedFat
  case fiber
  case cholesterol
  case sodium
  case calcium
  case iron
  case potassium
  case magnesium
  case zinc
  case vitaminA
  case vitaminB6
  case vitaminB12
  case vitaminC
  case vitaminD
  case vitaminE

  var identifier: HKQuantityTypeIdentifier {
    switch self {
    case .calories: .dietaryEnergyConsumed
    case .protein: .dietaryProtein
    case .carbohydrates: .dietaryCarbohydrates
    case .fat: .dietaryFatTotal
    case .saturatedFat: .dietaryFatSaturated
    case .polyunsaturatedFat: .dietaryFatPolyunsaturated
    case .monounsaturatedFat: .dietaryFatMonounsaturated
    case .fiber: .dietaryFiber
    case .sugar: .dietarySugar
    case .cholesterol: .dietaryCholesterol
    case .sodium: .dietarySodium
    case .calcium: .dietaryCalcium
    case .iron: .dietaryIron
    case .potassium: .dietaryPotassium
    case .magnesium: .dietaryMagnesium
    case .zinc: .dietaryZinc
    case .vitaminA: .dietaryVitaminA
    case .vitaminB6: .dietaryVitaminB6
    case .vitaminB12: .dietaryVitaminB12
    case .vitaminC: .dietaryVitaminC
    case .vitaminD: .dietaryVitaminD
    case .vitaminE: .dietaryVitaminE
    }
  }

  var unit: HKUnit {
    switch self {
    case .calories: .largeCalorie()
    case .protein: .gram()
    case .carbohydrates: .gram()
    case .fat: .gram()
    case .saturatedFat: .gram()
    case .polyunsaturatedFat: .gram()
    case .monounsaturatedFat: .gram()
    case .fiber: .gram()
    case .sugar: .gram()
    case .cholesterol: .gramUnit(with: .milli)
    case .sodium: .gramUnit(with: .milli)
    case .calcium: .gramUnit(with: .milli)
    case .iron: .gramUnit(with: .milli)
    case .potassium: .gramUnit(with: .milli)
    case .magnesium: .gramUnit(with: .milli)
    case .zinc: .gramUnit(with: .milli)
    case .vitaminA: .gramUnit(with: .milli)
    case .vitaminB6: .gramUnit(with: .milli)
    case .vitaminB12: .gramUnit(with: .milli)
    case .vitaminC: .gramUnit(with: .milli)
    case .vitaminD: .gramUnit(with: .milli)
    case .vitaminE: .gramUnit(with: .milli)
    }
  }

  func value(for foodItem: FoodItemDTO) -> Double? {
    switch self {
    case .calories: foodItem.calories
    case .protein: foodItem.protein
    case .carbohydrates: foodItem.carbohydrates
    case .fat: foodItem.fat
    case .saturatedFat: foodItem.saturatedFat
    case .polyunsaturatedFat: foodItem.polyunsaturatedFat
    case .monounsaturatedFat: foodItem.monounsaturatedFat
    case .fiber: foodItem.fiber
    case .sugar: foodItem.sugar
    case .cholesterol: foodItem.cholesterol
    case .sodium: foodItem.sodium
    case .calcium: foodItem.calcium
    case .iron: foodItem.iron
    case .potassium: foodItem.potassium
    case .magnesium: foodItem.magnesium
    case .zinc: foodItem.zinc
    case .vitaminA: foodItem.vitaminA
    case .vitaminB6: foodItem.vitaminB6
    case .vitaminB12: foodItem.vitaminB12
    case .vitaminC: foodItem.vitaminC
    case .vitaminD: foodItem.vitaminD
    case .vitaminE: foodItem.vitaminE
    }
  }
}
