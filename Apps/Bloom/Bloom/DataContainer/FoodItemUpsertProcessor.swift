//
//  FoodItemUpsertProcessor.swift
//  Bloom
//
//  Created by Claude on 2025-10-24.
//

import Foundation
import SwiftData
import BloomModel
import DataContainer
import CoreHealth
import TelemetryDeck

public actor FoodItemUpsertProcessor {
  public static let shared = FoodItemUpsertProcessor()

  init() {}

  /// Upserts food items into the local database if they already exist.
  /// Only updates existing food item records (previously logged items).
  /// Silently ignores errors and runs in the background.
  public func upsertFoodItems(_ foodItems: [BloomModel.FoodItem]) async {
    do {
      let modelContext = ModelContext(ContainerHolder.shared.container)
      var didMakeChanges = false

      for foodItem in foodItems {
        // Check if this food item already exists in the database
        if let existingFoodItem = try modelContext.fetchFirstFoodItem(for: foodItem.id.value) {
          // Apply the updated data from the backend
          let wasModified = existingFoodItem.apply(foodItem: foodItem)
          if wasModified {
            didMakeChanges = true
          }
        }
        // If it doesn't exist, skip it (we only update previously logged items)
      }

      // Only save if we actually made changes
      if didMakeChanges {
        try modelContext.save()
      }
    } catch {
      TelemetryDeck.errorOccurred(
        id: "FoodItemUpsertProcessor.upsertFoodItems",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }
}
