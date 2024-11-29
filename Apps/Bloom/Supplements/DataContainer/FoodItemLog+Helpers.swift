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
