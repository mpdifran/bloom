//
//  IntentDonator.swift
//  Bloom
//
//  Created by Assistant on 2025-10-17.
//

import AppIntents
import Foundation
import BloomModel
import DataContainer
import CoreHealth

/// Centralized utility for donating AppIntents to the system for Siri suggestions.
@MainActor
enum IntentDonator {

  /// Donates any AppIntent to the system.
  /// - Parameter intent: The intent to donate.
  static func donate<T: AppIntent>(_ intent: T) async {
    do {
      try await intent.donate()
    } catch {
      // Silently fail - intent donation is a nice-to-have feature
      print("Failed to donate intent: \(error)")
    }
  }

  /// Convenience method to donate a meal logging intent.
  /// - Parameters:
  ///   - foodItemServings: The food items and their serving amounts.
  ///   - meal: The meal type (breakfast, lunch, dinner, snack).
  ///   - numberOfServings: The number of servings.
  static func donateMealLog(
    foodItemServings: [FoodItemServingAmount],
    meal: FoodItemLog.Meal,
    numberOfServings: Double
  ) async {
    let entities = foodItemServings.map { makeFoodItemEntity(from: $0.foodItem) }
    let mealOption = MealOption(from: meal)
    let intent = LogMealIntent(
      foodItems: entities,
      mealOption: mealOption,
      servings: numberOfServings
    )

    await donate(intent)
  }

  /// Converts a FoodItem from BloomModel to a FoodItemEntity for AppIntents.
  /// This helper exists in the main app target to avoid linking BloomModel to widget extensions.
  private static func makeFoodItemEntity(from foodItem: FoodItem) -> FoodItemEntity {
    FoodItemEntity(
      id: foodItem.id.value,
      name: foodItem.name,
      brandName: foodItem.brandName,
      flavour: foodItem.flavour,
      calories: foodItem.calories?.value,
      protein: foodItem.protein?.value,
      carbs: foodItem.carbohydrates?.value,
      fat: foodItem.fat?.value
    )
  }
}
