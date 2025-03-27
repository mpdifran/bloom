//
//  ModelContext+FoodItems.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftData

public extension ModelContext {

  func fetchFirstFoodItem(for id: String) throws -> FoodItemRecord? {
    let descriptor = FetchDescriptor<FoodItemRecord>(
      predicate: #Predicate<FoodItemRecord> { model in
        model.id == id
      }
    )
    return try fetch(descriptor).first
  }

  func fetchAllFoodItems(for id: String) throws -> [FoodItemRecord] {
    let descriptor = FetchDescriptor<FoodItemRecord>(
      predicate: #Predicate<FoodItemRecord> { model in
        model.id == id
      }
    )
    return try fetch(descriptor)
  }

  /// Merges food items that have the same ID as the first food item, maintaining relationships. Properties are not merged.
  func merge(_ foodItems: [FoodItemRecord]) throws -> FoodItemRecord? {
    guard let firstFoodItem = foodItems.first else { return nil }

    let id = firstFoodItem.id
    let remainingFoodItems = foodItems.dropFirst().filter({ $0.id == id })

    for foodItem in remainingFoodItems {
      for serving in foodItem.servings ?? [] {
        serving.foodItem = firstFoodItem
      }
      for mealItem in foodItem.mealItems ?? [] {
        mealItem.foodItem = firstFoodItem
      }
      delete(foodItem)
    }

    try save()

    return firstFoodItem
  }
}
