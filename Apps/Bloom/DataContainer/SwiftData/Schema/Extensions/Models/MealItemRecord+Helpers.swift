//
//  MealItemRecord+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import Foundation

public extension MealItemRecord {

  var totalCalories: Double {
    (foodItem?.calories ?? 0) * numberOfServings
  }

  var totalProtein: Double {
    (foodItem?.protein ?? 0) * numberOfServings
  }

  var totalCarbs: Double {
    (foodItem?.carbohydrates ?? 0) * numberOfServings
  }

  var totalFat: Double {
    (foodItem?.fat ?? 0) * numberOfServings
  }
}
