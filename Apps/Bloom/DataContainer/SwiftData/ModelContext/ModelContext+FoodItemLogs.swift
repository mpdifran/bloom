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
}
