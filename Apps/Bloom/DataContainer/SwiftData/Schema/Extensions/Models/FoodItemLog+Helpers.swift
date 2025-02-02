//
//  FoodItemLog+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-01.
//

import Foundation

public extension FoodItemLog.Meal {
  var name: String {
    rawValue.capitalized
  }
}

public extension FoodItemLog {
  // This is a stop-gap while implementing Meals.
  // There is some additional work to assume a log can have multiple food items to make up a Meal
  // TODO: Zach - clean up once meals are implemented.
  var foodItem: FoodItemRecord? {
    foodItemServings?.first?.foodItem
  }
}
