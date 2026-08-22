//
//  FoodItemLog+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-01.
//

import Foundation
import SwiftUI

public extension FoodItemLog.Meal {
  /// The user-facing name. `rawValue` stays canonical English — it is a persistence identifier.
  var name: String {
    switch self {
    case .breakfast: String(localized: "Breakfast", bundle: Bundle.dataContainer, comment: "Display name for a meal")
    case .lunch: String(localized: "Lunch", bundle: Bundle.dataContainer, comment: "Display name for a meal")
    case .dinner: String(localized: "Dinner", bundle: Bundle.dataContainer, comment: "Display name for a meal")
    case .snack: String(localized: "Snack", bundle: Bundle.dataContainer, comment: "Display name for a meal")
    }
  }
}

public extension FoodItemLog {
  @available(*, deprecated, message: "Use `foodItemServings` properties instead.")
  var foodItem: FoodItemRecord? {
    foodItemServings?.first?.foodItem
  }

  var hasSingleServing: Bool {
    foodItemServings?.count == 1
  }

  var firstFoodItemServing: FoodItemServing? {
    foodItemServings?.first
  }

  func serving(for foodItemID: String) -> FoodItemServing? {
    foodItemServings?.first(where: { $0.foodItem?.id == foodItemID })
  }

  var image: UIImage? {
    guard let imageData else { return nil }

    return UIImage(data: imageData)
  }

  var isFullyVerified: Bool {
    foodItemServings?.contains(where: { $0.foodItem?.isVerified == false }) == false
  }
}

public extension FoodItemLog {

  var totalCalories: Double {
    let calories = foodItemServings?.reduce(0, { partialResult, serving in
      partialResult + serving.totalCalories
    }) ?? 0
    return numberOfServings * calories
  }

  var totalProtein: Double {
    let value = foodItemServings?.reduce(0, { partialResult, serving in
      let value = (serving.foodItem?.protein ?? 0) * serving.numberOfServings
      return partialResult + value
    }) ?? 0
    return numberOfServings * value
  }

  var totalCarbs: Double {
    let value = foodItemServings?.reduce(0, { partialResult, serving in
      let value = (serving.foodItem?.carbohydrates ?? 0) * serving.numberOfServings
      return partialResult + value
    }) ?? 0
    return numberOfServings * value
  }

  var totalFat: Double {
    let value = foodItemServings?.reduce(0, { partialResult, serving in
      let value = (serving.foodItem?.fat ?? 0) * serving.numberOfServings
      return partialResult + value
    }) ?? 0
    return numberOfServings * value
  }
}

public extension [FoodItemLog] {
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
