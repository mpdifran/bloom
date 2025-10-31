//
//  LogMealTimelineProvider.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-16.
//

import Foundation
import WidgetKit
import AppIntents
import BloomFoundation
import DataContainer

struct LogMealTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = LogMealEntry
  typealias Intent = LogMealConfigurationIntent

  func placeholder(in context: Context) -> LogMealEntry {
    LogMealEntry(
      date: Date(),
      relevance: TimelineEntryRelevance(score: 0.5),
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

  private func calculateRelevance(for meal: MealOption, at date: Date) -> TimelineEntryRelevance? {
    let hour = Calendar.current.component(.hour, from: date)

    switch meal {
    case .automatic:
      // Automatic mode adapts to current time, medium priority
      return TimelineEntryRelevance(score: 0.5)

    case .snack:
      // Snacks have no specific time window, medium priority
      return TimelineEntryRelevance(score: 0.5)

    case .breakfast:
      // Breakfast window: 6:00 AM - 10:59 AM
      let isInWindow = (6..<11).contains(hour)
      return TimelineEntryRelevance(score: isInWindow ? 1.0 : 0.0)

    case .lunch:
      // Lunch window: 11:00 AM - 3:59 PM
      let isInWindow = (11..<16).contains(hour)
      return TimelineEntryRelevance(score: isInWindow ? 1.0 : 0.0)

    case .dinner:
      // Dinner window: 4:00 PM - 11:59 PM
      let isInWindow = (16..<24).contains(hour)
      return TimelineEntryRelevance(score: isInWindow ? 1.0 : 0.0)
    }
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

    // Calculate relevance based on meal selection and current time
    let relevance = calculateRelevance(for: meal, at: Date())

    return LogMealEntry(
      date: Date(),
      relevance: relevance,
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
