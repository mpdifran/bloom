//
//  LogMealConfigurationIntent.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-16.
//

import AppIntents
import Foundation
import WidgetKit

struct LogMealConfigurationIntent: WidgetConfigurationIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Log Meal Configuration"
  nonisolated(unsafe) static var description = IntentDescription("Configure which meal to log with the widget.")

  @Parameter(title: "Meal Name (Optional)")
  var mealName: String?

  @Parameter(title: "Food Items")
  var foodItems: [FoodItemEntity]?

  @Parameter(title: "Meal Type", default: .automatic)
  var mealOption: MealOption?

  @Parameter(title: "Servings per item", default: 1.0)
  var servings: Double?

  init() {
    self.mealName = nil
    self.foodItems = nil
    self.mealOption = .automatic
    self.servings = 1.0
  }

  init(
    mealName: String?,
    foodItems: [FoodItemEntity]?,
    mealOption: MealOption?,
    servings: Double?
  ) {
    self.mealName = mealName
    self.foodItems = foodItems
    self.mealOption = mealOption
    self.servings = servings
  }

  var displayName: String {
    // If custom name is provided, use it
    if let customName = mealName, !customName.isEmpty {
      return customName
    }

    // Default logic based on number of food items
    if let items = foodItems, items.count == 1 {
      return items[0].name // Use food name for single item
    } else {
      return "My Meal" // Multiple items default
    }
  }
}
