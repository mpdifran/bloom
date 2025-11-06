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
      isLogged: false,
      loggedFoodItemLogId: nil,
      mealOption: .automatic,
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

    // Calculate next midnight to reset the logged state
    let nextMidnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400)) // Tomorrow at midnight

    return Timeline(entries: [entry], policy: .after(nextMidnight))
  }

  private func calculateRelevance(for meal: MealOption, at date: Date, isLogged: Bool) -> TimelineEntryRelevance? {
    let hour = Calendar.current.component(.hour, from: date)

    var baseScore: Float

    switch meal {
    case .automatic:
      // Automatic mode adapts to current time, medium priority
      baseScore = 0.5

    case .snack:
      // Snacks have no specific time window, medium priority
      baseScore = 0.5

    case .breakfast:
      // Breakfast window: 6:00 AM - 10:59 AM
      let isInWindow = (6..<11).contains(hour)
      baseScore = isInWindow ? 1.0 : 0.0

    case .lunch:
      // Lunch window: 11:00 AM - 3:59 PM
      let isInWindow = (11..<16).contains(hour)
      baseScore = isInWindow ? 1.0 : 0.0

    case .dinner:
      // Dinner window: 4:00 PM - 11:59 PM
      let isInWindow = (16..<24).contains(hour)
      baseScore = isInWindow ? 1.0 : 0.0
    }

    // Reduce priority if already logged
    if isLogged {
      baseScore *= 0.3
    }

    return TimelineEntryRelevance(score: baseScore)
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

    // Check if food has been logged today
    var isLogged = false
    var loggedFoodItemLogId: String? = nil
    let modelContext = ContainerHolder.shared.createContext()

    // Convert meal option to actual meal for filtering
    let targetMeal = meal.toMeal()

    switch kind {
    case .singleFoodItem:
      if let foodItem = configuration.foodItem {
        totalCalories = (foodItem.calories ?? 0) * servings
        totalProtein = (foodItem.protein ?? 0) * servings
        totalCarbs = (foodItem.carbs ?? 0) * servings
        totalFat = (foodItem.fat ?? 0) * servings

        // Check if this food item has been logged today
        if let logs = try? modelContext.fetchFoodItemLogsToday(foodItemId: foodItem.id), !logs.isEmpty {
          // Filter by meal type if not automatic
          let filteredLogs = meal == .automatic ? logs : logs.filter { $0.meal == targetMeal }

          if !filteredLogs.isEmpty {
            isLogged = true
            loggedFoodItemLogId = filteredLogs.first?.id
          }
        }
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

          // Check if all food items in this meal have been logged today
          let foodItemIds = mealDTO.items.compactMap { $0.foodItem?.id }
          if !foodItemIds.isEmpty,
             let logs = try? modelContext.fetchFoodItemLogsToday(foodItemIds: foodItemIds),
             !logs.isEmpty {
            // Filter by meal type if not automatic
            let filteredLogs = meal == .automatic ? logs : logs.filter { $0.meal == targetMeal }

            if !filteredLogs.isEmpty {
              isLogged = true
              loggedFoodItemLogId = filteredLogs.first?.id
            }
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

    // Calculate relevance based on meal selection, current time, and logged state
    let relevance = calculateRelevance(for: meal, at: Date(), isLogged: isLogged)

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
      isLogged: isLogged,
      loggedFoodItemLogId: loggedFoodItemLogId,
      mealOption: meal,
      intent: intent
    )
  }
}
