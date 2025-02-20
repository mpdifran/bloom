//
//  FoodItemLog+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-26.
//

import DataContainer

extension FoodItemLog {

  var totalCalories: Double {
    numberOfServings * (foodItem?.calories ?? 0)
  }

  var totalProtein: Double {
    numberOfServings * (foodItem?.protein ?? 0)
  }

  var totalCarbs: Double {
    numberOfServings * (foodItem?.carbohydrates ?? 0)
  }

  var totalFat: Double {
    numberOfServings * (foodItem?.fat ?? 0)
  }

  var totalServingAmount: Double {
    numberOfServings * (foodItem?.servingValue ?? 0)
  }
}

extension [FoodItemLog] {
  var totalCalories: Double {
    reduce(0) { partialResult, foodItemLog in
      partialResult + foodItemLog.totalCalories
    }
  }

  var totalProtein: Double {
    reduce(0) { partialResult, foodItemLog in
      partialResult + foodItemLog.totalProtein
    }
  }

  var totalCarbs: Double {
    reduce(0) { partialResult, foodItemLog in
      partialResult + foodItemLog.totalCarbs
    }
  }

  var totalFat: Double {
    reduce(0) { partialResult, foodItemLog in
      partialResult + foodItemLog.totalFat
    }
  }
}
