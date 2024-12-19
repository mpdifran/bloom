//
//  SearchFoodStore.swift
//  Gardener
//
//  Created by Zach Radford on 2024-12-18.
//

import BloomModel
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

    // TODO: make query and populate foodItems
  }
}
