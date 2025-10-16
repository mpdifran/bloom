//
//  FoodItemQuery.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-16.
//

import AppIntents
import Foundation
import SwiftData
import DataContainer

struct FoodItemQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [FoodItemEntity] {
    let modelActor = FoodItemLogModelActor.standard()

    var foodItems = [FoodItemEntity]()
    for identifier in identifiers {
      if let foodItemDTO = try await modelActor.fetchFoodItem(for: identifier) {
        foodItems.append(FoodItemEntity(from: foodItemDTO))
      }
    }

    return foodItems
  }

  func suggestedEntities() async throws -> [FoodItemEntity] {
    let modelActor = FoodItemLogModelActor.standard()

    // Fetch frequently logged foods (last 2 months, all meals)
    let frequentFoods = try await modelActor.fetchFrequentLogs(for: nil)

    // Limit to 30 items for good UX
    return frequentFoods.prefix(30).map { FoodItemEntity(from: $0) }
  }
}
