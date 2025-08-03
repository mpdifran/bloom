//
//  FoodItemModelActor.swift
//  DataContainer
//
//  Created by Claude on 2025-08-02.
//

import Foundation
import SwiftData

@ModelActor
public final actor FoodItemModelActor: SharedModelActor {
  
  private var context: ModelContext { modelExecutor.modelContext }
}

public extension FoodItemModelActor {
  
  func fetchFoodItem(for id: String) throws -> FoodItemDTO? {
    try context.fetchFirstFoodItem(for: id)?.asDTO()
  }
  
  func fetchFoodItems(for ids: [String]) throws -> [FoodItemDTO] {
    ids.compactMap { id in
      try? context.fetchFirstFoodItem(for: id)?.asDTO()
    }
  }
}