//
//  LogMealToggleIntent.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-17.
//

import AppIntents
import Foundation
import SwiftData
import DataContainer
import CoreHealth

struct LogMealToggleIntent: SetValueIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Log Meal"
  nonisolated(unsafe) static var description = IntentDescription("Logs a meal with one or more food items.")

  @Parameter(title: "Widget Type")
  var kind: LogMealWidgetType

  // Single Food Item parameters
  @Parameter(title: "Food Item")
  var foodItem: FoodItemEntity?

  // Saved Meal parameters
  @Parameter(title: "Saved Meal")
  var savedMeal: MealEntity?

  // Common parameters
  @Parameter(title: "Meal", default: .automatic)
  var meal: MealOption

  @Parameter(title: "Servings", default: 1.0)
  var servings: Double

  @Parameter(title: "Value")
  var value: Bool

  init() {
    self.kind = .singleFoodItem
    self.foodItem = nil
    self.savedMeal = nil
    self.meal = .automatic
    self.servings = 1.0
    self.value = false
  }

  init(
    kind: LogMealWidgetType,
    foodItem: FoodItemEntity?,
    savedMeal: MealEntity?,
    meal: MealOption,
    servings: Double
  ) {
    self.kind = kind
    self.foodItem = foodItem
    self.savedMeal = savedMeal
    self.meal = meal
    self.servings = servings
    self.value = false
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    // Convert meal option to actual meal based on current time
    let mealValue = meal.toMeal()

    // Create model context
    let modelContext = ContainerHolder.shared.createContext()

    // Build FoodItemServingAmounts based on widget type
    var foodItemServingAmounts = [FoodItemServingAmount]()
    var logName: String

    switch kind {
    case .singleFoodItem:
      guard let foodItemEntity = foodItem else {
        return .result()
      }

      // Fetch the full FoodItem from the database
      guard let foodItemRecord = try modelContext.fetchFirstFoodItem(for: foodItemEntity.id) else {
        return .result()
      }

      let foodItemModel = foodItemRecord.asNetworkFoodItem()
      foodItemServingAmounts.append(FoodItemServingAmount(
        serving: servings,
        foodItem: foodItemModel
      ))

      logName = foodItemEntity.name

    case .savedMeal:
      guard let mealEntity = savedMeal else {
        return .result()
      }

      // Fetch the saved meal
      let mealActor = MealRecordModelActor.standard()
      guard let mealDTO = try await mealActor.fetchMealRecord(for: mealEntity.id) else {
        return .result()
      }

      // Convert each meal item to FoodItemServingAmount, multiplied by servings
      for mealItem in mealDTO.items {
        guard let foodItemDTO = mealItem.foodItem else { continue }

        guard let foodItemRecord = try modelContext.fetchFirstFoodItem(for: foodItemDTO.id) else {
          continue
        }

        let foodItemModel = foodItemRecord.asNetworkFoodItem()
        foodItemServingAmounts.append(FoodItemServingAmount(
          serving: mealItem.numberOfServings * servings,
          foodItem: foodItemModel
        ))
      }

      logName = mealEntity.name
    }

    // Log the meal with individual servings
    let viewModel = NutritionTrackingViewModel.shared
    _ = try await viewModel.log(
      modelContext: modelContext,
      name: logName,
      imageData: nil,
      numberOfServings: 1.0,
      foodItemServings: foodItemServingAmounts,
      date: Date(),
      meal: mealValue
    )

    // Return success - the toggle will automatically revert when the widget timeline reloads
    return .result()
  }
}
