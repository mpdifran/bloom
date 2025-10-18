//
//  LogMealTimelineProvider.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-16.
//

import Foundation
import WidgetKit
import AppIntents

struct LogMealTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = LogMealEntry
  typealias Intent = LogMealConfigurationIntent

  func placeholder(in context: Context) -> LogMealEntry {
    LogMealEntry(
      date: Date(),
      displayName: "Protein Shake",
      mealName: "Breakfast",
      caloriesText: "300 cal",
      proteinGrams: 25,
      carbsGrams: 10,
      fatGrams: 3,
      foodItemNames: nil,
      servingsDescription: "1 serving",
      intent: LogMealToggleIntent(foodItems: [], mealOption: .automatic, servings: 1.0)
    )
  }

  func snapshot(for configuration: LogMealConfigurationIntent, in context: Context) async -> LogMealEntry {
    makeEntry(from: configuration)
  }

  func timeline(for configuration: LogMealConfigurationIntent, in context: Context) async -> Timeline<LogMealEntry> {
    let entry = makeEntry(from: configuration)
    return Timeline(entries: [entry], policy: .never)
  }

  private func makeEntry(from configuration: LogMealConfigurationIntent) -> LogMealEntry {
    let foodItems = configuration.foodItems ?? []
    let servings = configuration.servings ?? 1.0
    let mealOption = configuration.mealOption ?? .automatic

    // Calculate total macros
    let totalCalories = foodItems.compactMap { $0.calories }.reduce(0, +)
    let totalProtein = foodItems.compactMap { $0.protein }.reduce(0, +)
    let totalCarbs = foodItems.compactMap { $0.carbs }.reduce(0, +)
    let totalFat = foodItems.compactMap { $0.fat }.reduce(0, +)

    // Generate calories text
    let caloriesText: String? = totalCalories > 0 ? "\(Int(totalCalories)) cal" : nil

    // Generate food item names for multi-item display
    let foodItemNames: String? = {
      guard foodItems.count > 1 else { return nil }
      let names = foodItems.map { $0.name }
      let formatter = ListFormatter()
      return formatter.string(from: names)
    }()

    // Generate servings description
    let servingsDescription = servings == 1.0 ? "1 serving" : "\(servings) servings"

    // Generate meal name
    let mealName: String = {
      switch mealOption {
      case .automatic:
        return "Automatic"
      case .breakfast:
        return "Breakfast"
      case .lunch:
        return "Lunch"
      case .dinner:
        return "Dinner"
      case .snack:
        return "Snack"
      }
    }()

    // Create intent for the toggle
    let intent = LogMealToggleIntent(
      foodItems: foodItems,
      mealOption: mealOption,
      servings: servings
    )

    return LogMealEntry(
      date: Date(),
      displayName: configuration.displayName,
      mealName: mealName,
      caloriesText: caloriesText,
      proteinGrams: totalProtein,
      carbsGrams: totalCarbs,
      fatGrams: totalFat,
      foodItemNames: foodItemNames,
      servingsDescription: servingsDescription,
      intent: intent
    )
  }
}
