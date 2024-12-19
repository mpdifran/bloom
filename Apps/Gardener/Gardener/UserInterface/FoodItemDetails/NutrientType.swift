//
//  NutrientType.swift
//  Gardener
//
//  Created by Zach Radford on 2024-12-18.
//

import Foundation

enum NutrientType {
  case calories
  case carbs
  case fiber
  case sugar
  case fat
  case saturatedFat
  case transFat
  case polyunsaturatedFat
  case monounsaturatedFat
  case protein
  case vitaminA
  case vitaminB6
  case vitaminB12
  case vitaminC
  case vitaminD
  case vitaminE
  case sodium
  case calcium
  case iron
  case potassium
  case magnesium
  case zinc
  case cholesterol

  var displayName: String {
    switch self {
    case .calories: "Calories"
    case .carbs: "Carbohydrates"
    case .fiber: "Fiber"
    case .sugar: "Sugar"
    case .fat: "Fat"
    case .saturatedFat: "Saturated Fat"
    case .transFat: "Trans Fat"
    case .polyunsaturatedFat: "Polyunsaturated Fat"
    case .monounsaturatedFat: "Monounsaturated Fat"
    case .protein: "Protein"
    case .vitaminA: "Vitamin A"
    case .vitaminB6: "Vitamin B6"
    case .vitaminB12: "Vitamin B12"
    case .vitaminC: "Vitamin C"
    case .vitaminD: "Vitamin D"
    case .vitaminE: "Vitamin E"
    case .sodium: "Sodium"
    case .calcium: "Calcium"
    case .iron: "Iron"
    case .potassium: "Potassium"
    case .magnesium: "Magnesium"
    case .zinc: "Zinc"
    case .cholesterol: "Cholesterol"
    }
  }

  /// In milligrams.
  /// From https://www.canada.ca/en/health-canada/services/technical-documents-labelling-requirements/table-daily-values/nutrition-labelling.html.
  var dailyValueAmount: Double? {
    switch self {
    case .calories: nil // don't support this
    case .carbs: nil // don't support this
    case .fiber: 28000
    case .sugar: 100000
    case .fat: 75000
    case .saturatedFat: 20000
    case .transFat: 20000
    case .polyunsaturatedFat: 20000
    case .monounsaturatedFat: 20000
    case .protein: nil // don't support this
    case .vitaminA: 0.9
    case .vitaminB6: 1.7
    case .vitaminB12: 0.0024
    case .vitaminC: 90
    case .vitaminD: 0.02
    case .vitaminE: 15
    case .sodium: 2300
    case .calcium: 1300
    case .iron: 18
    case .potassium: 3400
    case .magnesium: 420
    case .zinc: 11
    case .cholesterol: 300
    }
  }
}
