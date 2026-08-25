//
//  BaseFoodStore.swift
//  Gardener
//
//  Created by Zach Radford on 2024-12-18.
//

import AdminBloomModel
import Foundation
import SwiftUI

@MainActor
class BaseFoodStore: ObservableObject {
  @Published var foodItems: [AdminFoodItemRecord] = []

  internal let service = NetworkStack.shared

  func loadItems() async {
    print("Warning! Not implemented, please implement in subclass.")
  }

  func update(
    foodItem: AdminFoodItemRecord,
    nutritionLabelImage: NSImage?,
    packagingImage: NSImage?
  ) async throws -> AdminFoodItemRecord? {
    var nutritionLabelImageFile: ImageFile?
    if let nutritionLabelImage, let nutritionData = nutritionLabelImage.pngData() {
      nutritionLabelImageFile = ImageFile(
        data: nutritionData,
        fileExtension: "png"
      )
    }

    var packagingImageFile: ImageFile?
    if let packagingImage, let packagingData = packagingImage.pngData() {
      packagingImageFile = ImageFile(
        data: packagingData,
        fileExtension: "png"
      )
    }

    let request = AdminUpdateFoodItemRequest(
      foodItemRecord: foodItem,
      nutritionLabelImage: nutritionLabelImageFile,
      packagingImage: packagingImageFile
    )
    let response = try await service.replaceFoodRecord(request: request)

    guard let updatedFoodItem = response.foodItemRecord else {
      throw NSError(description: "Nil Food Item Response")
    }

    guard let index = foodItems.firstIndex(where: { $0.id == updatedFoodItem.id}) else {
      return nil
    }

    foodItems[index] = updatedFoodItem

    return updatedFoodItem
  }

  func delete(_ foodItem: AdminFoodItemRecord) async throws {
    try await service.deleteFoodRecord(id: foodItem.id)
    guard let index = foodItems.firstIndex(where: { $0.id == foodItem.id}) else { return }
    foodItems.remove(at: index)
  }
}
