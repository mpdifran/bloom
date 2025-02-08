//
//  CreateNewFoodItemDetailViewModel.swift
//  Gardener
//
//  Created by Haocen Jiang on 2025-01-23.
//

import AdminBloomModel
import BloomModel
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class CreateNewFoodItemDetailViewModel: FoodItemDetailViewModel {
  private let service = NetworkStack.shared
  private let dismissWindow: () -> Void

  init(dismissWindow: @escaping () -> Void) {
    self.dismissWindow = dismissWindow
    super.init(
      foodItem: AdminFoodItemRecord(id: FoodItemIdentifier(UUID().uuidString)),
      foodStore: UnverifiedFoodStore.shared // no needed
    )
    saveButtonText = "Create and close window"
  }
  
  override func save() async {
    do {
      let response = try await create(
        foodItem: foodItem,
        nutritionLabelImage: selectedNutritionLabel,
        packagingImage: selectedPackagingImage
      )
      
      guard let updatedFoodItem = response.foodItemRecord else { return }
      foodItem = updatedFoodItem
      resetInitialFoodItem(to: updatedFoodItem)
      packagingImage = updatedFoodItem.packagingImage
      nutritionLabel = updatedFoodItem.nutritionLabelImage
      // Reset selections, they should be on the response.
      selectedPackagingImage = nil
      selectedNutritionLabel = nil
      
      await MainActor.run { dismissWindow() }
      
    } catch {
      await MainActor.run { self.error = error }
    }
  }
  
  override func delete() async {
    await MainActor.run { dismissWindow() }
  }
  
  @discardableResult
  private func create(
    foodItem: AdminFoodItemRecord,
    nutritionLabelImage: NSImage?,
    packagingImage: NSImage?
  ) async throws -> AdminCreateFoodItemResponse {
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

    let request = AdminCreateFoodItemRequest(
      foodItemRecord: foodItem,
      nutritionLabelImage: nutritionLabelImageFile,
      packagingImage: packagingImageFile
    )
    
    return try await service.createFoodRecord(request: request)
  }
}
