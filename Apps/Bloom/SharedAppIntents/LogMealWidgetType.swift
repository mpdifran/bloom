//
//  LogMealWidgetType.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-18.
//

import AppIntents
import Foundation

enum LogMealWidgetType: String, AppEnum {
  case singleFoodItem
  case savedMeal

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widget Type")

  static var caseDisplayRepresentations: [LogMealWidgetType: DisplayRepresentation] = [
    .singleFoodItem: "Single Food Item",
    .savedMeal: "Saved Meal"
  ]
}
