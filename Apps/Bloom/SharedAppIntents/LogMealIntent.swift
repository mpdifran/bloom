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
import CoreNetwork
import AppFoundations

struct LogMealIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Log Meal"
  nonisolated(unsafe) static var description = IntentDescription("Logs a meal with one or more food items.")

  @Parameter(
    title: "Food Items",
    requestValueDialog: IntentDialog(full: "Which food item?", supporting: "Food?", systemImageName: "fork.knife"),
    requestDisambiguationDialog: IntentDialog("Which food item?")
  )
  var foodItems: [FoodItemEntity]

  @Parameter(
    title: "Meal",
    default: .automatic,
    requestValueDialog: IntentDialog("Which meal?")
  )
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
    // Validate that at least one food item was selected
    if foodItems.isEmpty {
      throw $foodItems.needsValueError(
        IntentDialog("Please select at least one food item to log")
      )
    }

    // Convert meal option to actual meal based on current time
    let meal = mealOption.toMeal()

    // Create model context
    let modelContext = ContainerHolder.shared.createContext()

    // Fetch full food item data using hybrid approach
    var foodItemServings = [FoodItemServingAmount]()

    for foodEntity in foodItems {
      // Try to fetch from database first (gets complete nutrition data)
      if let foodItemRecord = try modelContext.fetchFirstFoodItem(for: foodEntity.id) {
        let foodItem = foodItemRecord.asNetworkFoodItem()
        foodItemServings.append(FoodItemServingAmount(
          serving: servings,
          foodItem: foodItem
        ))
      } else {
        // Fallback: Fetch from backend API
        do {
          let foodItem = try await NetworkRequester.shared.getFoodItem(id: foodEntity.id)
          foodItemServings.append(FoodItemServingAmount(
            serving: servings,
            foodItem: foodItem
          ))
        } catch {
          // Skip items that can't be fetched
          continue
        }
      }
    }

    // Check if we have any items to log
    if foodItemServings.isEmpty {
      throw NSError(description: "Unable to fetch food data. Please try again.")
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
