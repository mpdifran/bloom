//
//  UnverifiedFoodStore.swift
//  Gardener
//
//  Created by Zach Radford on 2024-12-08.
//

import BloomModel
import Foundation
import SwiftUI

@MainActor
final class UnverifiedFoodStore: BaseFoodStore {
  override func loadItems() async {
    do {
      let response = try await service.getUnverifiedFoodRecords(limit: 500)
      foodItems = response.foodItemRecords
    } catch {
      print("Error fetching unverified food records: \(error)")
    }
  }
}
