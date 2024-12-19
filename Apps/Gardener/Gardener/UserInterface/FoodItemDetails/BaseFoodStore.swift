//
//  BaseFoodStore.swift
//  Gardener
//
//  Created by Zach Radford on 2024-12-18.
//

import BloomModel
import Foundation
import SwiftUI

@MainActor
class BaseFoodStore: ObservableObject {
  @Published var foodItems: [AdminFoodItemRecord] = []

  internal let service = NetworkStack.shared

  func loadItems() async {
    print("Warning! Not implemented, please implement in subclass.")
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

  func delete(_ foodItem: AdminFoodItemRecord) async {
    do {
      try await service.deleteFoodRecord(id: foodItem.id)
      guard let index = foodItems.firstIndex(where: { $0.id == foodItem.id}) else { return }
      foodItems.remove(at: index)

    } catch {
      print("Error deleting food record: \(error)")
    }
  }
}
