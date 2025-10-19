//
//  LogMealTimelineProvider.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-16.
//

import Foundation
import WidgetKit
import AppIntents
internal import BloomFoundation
import DataContainer

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
      intent: LogMealToggleIntent(
        kind: .singleFoodItem,
        foodItem: nil,
        savedMeal: nil,
        meal: .automatic,
        servings: 1.0
      )
    )
  }

  func snapshot(for configuration: LogMealConfigurationIntent, in context: Context) async -> LogMealEntry {
    await makeEntry(from: configuration)
  }

  func timeline(for configuration: LogMealConfigurationIntent, in context: Context) async -> Timeline<LogMealEntry> {
    let entry = await makeEntry(from: configuration)
    return Timeline(entries: [entry], policy: .never)
  }

  private func makeEntry(from configuration: LogMealConfigurationIntent) async -> LogMealEntry {
    let kind = configuration.kind ?? .singleFoodItem
    let servings = configuration.servings ?? 1.0
    let meal = configuration.meal ?? .automatic

    // Calculate total macros based on widget type
    var totalCalories: Double = 0
    var totalProtein: Double = 0
    var totalCarbs: Double = 0
    var totalFat: Double = 0
    var foodItemNames: String? = nil

    switch kind {
    case .singleFoodItem:
      if let foodItem = configuration.foodItem {
        totalCalories = (foodItem.calories ?? 0) * servings
        totalProtein = (foodItem.protein ?? 0) * servings
        totalCarbs = (foodItem.carbs ?? 0) * servings
        totalFat = (foodItem.fat ?? 0) * servings
      }

    case .savedMeal:
      if let savedMeal = configuration.savedMeal {
        // Fetch the meal to get its items
        let mealActor = MealRecordModelActor.standard()
        if let mealDTO = try? await mealActor.fetchMealRecord(for: savedMeal.id) {
          // Calculate totals from all meal items, multiplied by servings
          for mealItem in mealDTO.items {
            guard let foodItem = mealItem.foodItem else { continue }

            let itemServing = mealItem.numberOfServings * servings
            totalCalories += foodItem.calories * itemServing
            totalProtein += foodItem.protein * itemServing
            totalCarbs += foodItem.carbohydrates * itemServing
            totalFat += foodItem.fat * itemServing
          }

          // Generate food item names for display
          if mealDTO.items.count > 1 {
            let names = mealDTO.items.compactMap { $0.foodItem?.name }
            let formatter = ListFormatter()
            foodItemNames = formatter.string(from: names)
          }
        }
      }
    }

    // Generate calories text
    let caloriesText: String? = totalCalories > 0 ? "\(Int(totalCalories)) cal" : nil

    // Generate servings description
    let servingsDescription = servings == 1.0
      ? "1 serving"
      : "\(servings.format(using: .twoDecimalPlaces)) servings"

    // Generate meal name
    let mealName: String = {
      switch meal {
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
      kind: kind,
      foodItem: configuration.foodItem,
      savedMeal: configuration.savedMeal,
      meal: meal,
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
