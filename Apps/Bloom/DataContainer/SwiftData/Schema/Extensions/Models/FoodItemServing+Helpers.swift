//
//  FoodItemServing+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-19.
//

import Foundation

public extension FoodItemServing {

  var totalCalories: Double {
    (foodItem?.calories ?? 0) * numberOfServings
  }
}
