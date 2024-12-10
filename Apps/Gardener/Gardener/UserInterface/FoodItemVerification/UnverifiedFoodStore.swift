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
final class UnverifiedFoodStore: ObservableObject {
  static let shared = UnverifiedFoodStore()

  @Published var foodItems: [AdminFoodItemRecord] = []

  private let service = NetworkStack.shared
}

extension UnverifiedFoodStore {
  func loadItems() async {
    do {
      let response = try await service.getUnverifiedFoodRecords(limit: 50)
      foodItems = response.foodItemRecords
    } catch {
      print("Error fetching unverified food records: \(error)")
    }
  }

  func update(_ foodItem: AdminFoodItemRecord) async {
    do {
      let request = AdminUpdateFoodItemRequest(foodItemRecord: foodItem)
      let response = try await service.updateFoodRecord(request: request)
      guard let updatedFoodItem = response.foodItemRecord else {
        // Nothing to update.
        return
      }
      guard let index = foodItems.firstIndex(where: { $0.id == updatedFoodItem.id}) else { return }
      foodItems[index] = updatedFoodItem

      // Copy over the images since the response won't included signed URLs.
      foodItems[index].packagingImage = foodItem.packagingImage
      foodItems[index].nutritionLabelImage = foodItem.nutritionLabelImage

    } catch {
      print("Error updating food record: \(error)")
    }
  }
}
