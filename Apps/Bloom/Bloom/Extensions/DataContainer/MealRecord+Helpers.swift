//
//  MealRecord+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-28.
//

import DataContainer

extension MealRecord {

  func contains(searchQuery: String) -> Bool {
    let foodItems = items?.compactMap {
      $0.foodItem?.asNetworkFoodItem()
    } ?? []

    return name.localizedCaseInsensitiveContains(searchQuery) ||
      foodItems.contains(where: { $0.contains(searchQuery: searchQuery) })
  }
}
