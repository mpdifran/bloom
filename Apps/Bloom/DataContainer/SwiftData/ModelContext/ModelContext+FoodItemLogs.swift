//
//  ModelContext+FoodItemLogs.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftData

public extension ModelContext {

  func fetchOldestFoodItemLog() throws -> FoodItemLog? {
    var descriptor = FetchDescriptor<FoodItemLog>(
      sortBy: [SortDescriptor(\FoodItemLog.date, order: .forward)]
    )
    descriptor.fetchLimit = 1
    return try fetch(descriptor).first
  }

  func fetchFoodItemLog(id: String) throws -> FoodItemLog?   {
    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate<FoodItemLog> { model in
        model.id == id
      }
    )
    return try fetch(descriptor).first
  }

  /// Fetches all food item logs for today that contain a specific food item ID
  func fetchFoodItemLogsToday(foodItemId: String) throws -> [FoodItemLog] {
    let startOfDay = Calendar.current.startOfDay(for: Date())
    let endOfDay = Calendar.current.endOfDay(for: Date())

    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate<FoodItemLog> { log in
        log.date >= startOfDay &&
        log.date <= endOfDay
      }
    )

    let allLogsToday = try fetch(descriptor)

    // Filter logs that contain the specific food item in their servings
    return allLogsToday.filter { log in
      guard let servings = log.foodItemServings else { return false }
      return servings.contains { serving in
        serving.foodItem?.id == foodItemId
      }
    }
  }

  /// Fetches all food item logs for today that contain all of the specified food item IDs
  func fetchFoodItemLogsToday(foodItemIds: [String]) throws -> [FoodItemLog] {
    guard !foodItemIds.isEmpty else { return [] }

    let startOfDay = Calendar.current.startOfDay(for: Date())
    let endOfDay = Calendar.current.endOfDay(for: Date())

    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate<FoodItemLog> { log in
        log.date >= startOfDay &&
        log.date <= endOfDay
      }
    )

    let allLogsToday = try fetch(descriptor)

    // Filter logs that contain all the specified food items
    return allLogsToday.filter { log in
      guard let servings = log.foodItemServings else { return false }
      let logFoodItemIds = Set(servings.compactMap { $0.foodItem?.id })

      // Check if all requested food item IDs are present in this log
      return Set(foodItemIds).isSubset(of: logFoodItemIds)
    }
  }
}
