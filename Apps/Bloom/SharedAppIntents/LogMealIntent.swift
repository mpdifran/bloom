//
//  LogMealIntent.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-16.
//

import AppIntents
import Foundation
import SwiftData
import DataContainer
import CoreHealth

struct LogMealIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Log Meal"
  nonisolated(unsafe) static var description = IntentDescription("Logs a meal with one or more food items.")

  @Parameter(title: "Food Items")
  var foodItems: [FoodItemEntity]

  @Parameter(title: "Meal", default: .automatic)
  var mealOption: MealOption

  @Parameter(title: "Servings", default: 1.0)
  var servings: Double

  init() {
    self.foodItems = []
    self.mealOption = .automatic
    self.servings = 1.0
  }

  init(foodItems: [FoodItemEntity], mealOption: MealOption, servings: Double) {
    self.foodItems = foodItems
    self.mealOption = mealOption
    self.servings = servings
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    // Convert meal option to actual meal based on current time
    let meal = mealOption.toMeal()

    // Create model context
    let modelContext = ContainerHolder.shared.createContext()

    // Convert food entities back to FoodItem for logging
    var foodItemServings = [FoodItemServingAmount]()

    for foodEntity in foodItems {
      // Fetch the full FoodItem from the database
      guard let foodItemRecord = try modelContext.fetchFirstFoodItem(for: foodEntity.id) else {
        continue
      }

      let foodItem = foodItemRecord.asNetworkFoodItem()
      foodItemServings.append(FoodItemServingAmount(
        serving: servings,
        foodItem: foodItem
      ))
    }

    // Log the food items
    let viewModel = NutritionTrackingViewModel.shared
    _ = try await viewModel.logIndividual(
      modelContext: modelContext,
      foodItemServings: foodItemServings,
      date: Date(),
      meal: meal
    )

    return .result()
  }
}
