//
//  SearchFoodStore.swift
//  Gardener
//
//  Created by Zach Radford on 2024-12-18.
//

import Foundation
import SwiftUI

@MainActor
final class SearchFoodStore: BaseFoodStore {

  @Published var searchQuery: String = ""

  override func loadItems() async {
    guard !searchQuery.isEmpty else {
      foodItems = []
      return
    }

    do {
      let response = try await service.searchFoodRecord(query: searchQuery)
      foodItems = response.foodItemRecords
    } catch {
      print("Error searching food records: \(error)")
    }
  }
}
