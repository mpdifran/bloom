//
//  FoodItemDetailViewModel.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import BloomModel
import Foundation
import SwiftUI

@MainActor
final class FoodItemDetailViewModel: ObservableObject {

  @Published var foodItem: AdminFoodItemRecord
  @Published var error: Error?

  private var initialFoodItem: AdminFoodItemRecord

  private let foodStore: BaseFoodStore

  @Published var packagingImage: URL?
  @Published var packagingImageRotation: Double = 0
  @Published var selectedPackagingImage: NSImage?

  @Published var nutritionLabel: URL?
  @Published var nutritionLabelRotation: Double = 0
  @Published var selectedNutritionLabel: NSImage?

  init(foodItem: AdminFoodItemRecord, foodStore: BaseFoodStore) {
    self.foodItem = foodItem
    self.initialFoodItem = foodItem
    self.foodStore = foodStore

    packagingImage = foodItem.packagingImage
    nutritionLabel = foodItem.nutritionLabelImage
  }
}

extension FoodItemDetailViewModel {

  func propertyChanged<T: Equatable>(_ keyPath: KeyPath<AdminFoodItemRecord, T>) -> Bool {
    foodItem[keyPath: keyPath] != initialFoodItem[keyPath: keyPath]
  }

  func propertyChanged<T: Equatable>(_ keyPath: KeyPath<AdminFoodItemRecord, T?>) -> Bool {
    foodItem[keyPath: keyPath] != initialFoodItem[keyPath: keyPath]
  }

  func save() async {
    do {
      try await foodStore.update(
        foodItem: foodItem,
        nutritionLabelImage: nil, // TODO: Zach - capture images uploaded/displayed from file system.
        packagingImage: nil
      )
      // Update with a new initial state.
      initialFoodItem = foodItem
    } catch {
      self.error = error
    }
  }

  func delete() async {
    do {
      try await foodStore.delete(foodItem)
    } catch {
      self.error = error
    }
  }

  func rotate(value: Double, image: FoodItemDetailView.ImageTab) {
    switch image {
    case .packaging:
      packagingImageRotation += value
    case .nutritionLabel:
      nutritionLabelRotation += value
    }
  }

  func selectImage(_ type: FoodItemDetailView.ImageTab) {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .jpeg, .heic, .pdf]
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false

    if panel.runModal() == .OK, let url = panel.url {
      if let selectedImage = NSImage(contentsOf: url) {
        switch type {
        case .packaging:
          selectedPackagingImage = selectedImage
        case .nutritionLabel:
          selectedNutritionLabel = selectedImage
        }
      } else {
        print("Failed to load image")
      }
    }
  }
}
