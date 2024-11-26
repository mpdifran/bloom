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

  var identifier: HKQuantityTypeIdentifier {
    switch self {
    case .calories: .dietaryEnergyConsumed
    case .protein: .dietaryProtein
    case .carbohydrates: .dietaryCarbohydrates
    case .fat: .dietaryFatTotal
    }
  }

  var unit: HKUnit {
    switch self {
    case .calories: .largeCalorie()
    case .protein: .gram()
    case .carbohydrates: .gram()
    case .fat: .gram()
    }
  }

  func getServingSize(_ foodItem: FoodItemDTO) -> Double {
    let servingValue = foodItem.servingValue ?? 0
    let value = switch self {
    case .calories: foodItem.calories
    case .protein: foodItem.protein
    case .carbohydrates: foodItem.carbohydrates
    case .fat: foodItem.fat
    }

    return servingValue * value
  }
}
