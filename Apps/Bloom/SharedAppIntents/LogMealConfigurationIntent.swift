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

  @Parameter(title: "Widget Type", default: .singleFoodItem)
  var kind: LogMealWidgetType?

  // Single Food Item parameters
  @Parameter(title: "Food Item")
  var foodItem: FoodItemEntity?

  // Saved Meal parameters
  @Parameter(title: "Saved Meal")
  var savedMeal: MealEntity?

  // Common parameters
  @Parameter(title: "Meal", default: .automatic)
  var meal: MealOption?

  @Parameter(title: "Servings", default: 1.0)
  var servings: Double?

  static var parameterSummary: some ParameterSummary {
    When(\.$kind, .equalTo, LogMealWidgetType.singleFoodItem) {
      Summary {
        \.$kind
        \.$foodItem
        \.$meal
        \.$servings
      }
    } otherwise: {
      Summary {
        \.$kind
        \.$savedMeal
        \.$meal
        \.$servings
      }
    }
  }

  init() {
    self.kind = .singleFoodItem
    self.foodItem = nil
    self.savedMeal = nil
    self.meal = .automatic
    self.servings = 1.0
  }

  init(
    kind: LogMealWidgetType?,
    foodItem: FoodItemEntity?,
    savedMeal: MealEntity?,
    meal: MealOption?,
    servings: Double?
  ) {
    self.kind = kind
    self.foodItem = foodItem
    self.savedMeal = savedMeal
    self.meal = meal
    self.servings = servings
  }

  var displayName: String {
    let type = kind ?? .singleFoodItem

    switch type {
    case .singleFoodItem:
      return foodItem?.name ?? String(localized: "Choose Food Item", comment: "Display name for log meal configuration intent")
    case .savedMeal:
      return savedMeal?.name ?? String(localized: "Choose Saved Meal", comment: "Display name for log meal configuration intent")
    }
  }
}
