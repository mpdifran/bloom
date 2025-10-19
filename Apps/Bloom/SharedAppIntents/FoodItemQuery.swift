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
import CoreNetwork
import BloomModel

struct FoodItemQuery: EntityQuery, EntityStringQuery {
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

    return frequentFoods.map { FoodItemEntity(from: $0) }
  }

  func entities(matching string: String) async throws -> [FoodItemEntity] {
    // Search backend for food items matching the query string
    let sections = try await NetworkRequester.shared.foodSearch(
      name: string,
      brand: nil,
      preferredCountry: "usa"
    )

    // Flatten all sections and convert to FoodItemEntity
    return sections.flatMap { $0.foods }.map { FoodItemEntity(from: $0) }
  }
}
