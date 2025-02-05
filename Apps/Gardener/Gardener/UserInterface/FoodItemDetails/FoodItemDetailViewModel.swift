//
//  FoodItemDetailViewModel.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import AdminBloomModel
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
open class FoodItemDetailViewModel: ObservableObject {

  @Published var foodItem: AdminFoodItemRecord
  @Published var error: Error?
  @Published var saveButtonText = "Save"
  private var initialFoodItem: AdminFoodItemRecord

  private let foodStore: BaseFoodStore

  @Published var packagingImage: URL?
  @Published var packagingImageRotation: Double = 0
  @Published var selectedPackagingImage: NSImage?
  @Published var accuracyReport: AdminAccuracyReport? = nil

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
  
  open func save() async {
    do {
      let updatedFoodItem = try await foodStore.update(
        foodItem: foodItem,
        nutritionLabelImage: selectedNutritionLabel,
        packagingImage: selectedPackagingImage
      )
      // Update with a new initial state.
      guard let updatedFoodItem else { return }
      foodItem = updatedFoodItem
      initialFoodItem = updatedFoodItem
      packagingImage = updatedFoodItem.packagingImage
      nutritionLabel = updatedFoodItem.nutritionLabelImage
      // Reset selections, they should be on the response.
      selectedPackagingImage = nil
      selectedNutritionLabel = nil
    } catch {
      self.error = error
    }
  }
  
  open func delete() async {
    do {
      try await foodStore.delete(foodItem)
    } catch {
      self.error = error
    }
  }
  
  func resetInitialFoodItem(to newItem: AdminFoodItemRecord) {
    initialFoodItem = newItem
  }
}

extension FoodItemDetailViewModel {
  func propertyChanged<T: Equatable>(_ keyPath: KeyPath<AdminFoodItemRecord, T>) -> Bool {
    foodItem[keyPath: keyPath] != initialFoodItem[keyPath: keyPath]
  }

  func propertyChanged<T: Equatable>(_ keyPath: KeyPath<AdminFoodItemRecord, T?>) -> Bool {
    foodItem[keyPath: keyPath] != initialFoodItem[keyPath: keyPath]
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
      let selectedImage = NSImage(contentsOf: url)
      setImage(image: selectedImage, for: type)
    }
  }

  func handleDrop(providers: [NSItemProvider], type: FoodItemDetailView.ImageTab) -> Bool {
    // Handle dropped URLs.
    if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
      provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { [weak self] item, _ in
        guard
          let data = item as? Data,
          let url = URL(dataRepresentation: data, relativeTo: nil) else {
          print("Failed to load file URL from drop")
          return
        }
        let selectedImage = NSImage(contentsOf: url)
        Task { @MainActor in
          self?.setImage(image: selectedImage, for: type)
        }
      }
      return true
    }

    // Handle dropped images.
    if let provider = providers.first(where: { $0.canLoadObject(ofClass: NSImage.self) }) {
      provider.loadObject(ofClass: NSImage.self) { [weak self] image, _ in
        guard let nsImage = image as? NSImage else {
          print("Failed to load image from drop")
          return
        }
        Task { @MainActor in
          self?.setImage(image: nsImage, for: type)
        }
      }
      return true
    }

    return false
  }
  
  func fetchAccuracyReport() async {
    do {
      let response = try await NetworkStack.shared.getLatestAccuracyReport(forFoodItemWithID: foodItem.id)
      await MainActor.run {
        self.accuracyReport = response.report
      }
    } catch { }
  }
}

private extension FoodItemDetailViewModel {

  func setImage(image: NSImage?, for type: FoodItemDetailView.ImageTab) {
    switch type {
    case .packaging:
      selectedPackagingImage = image
    case .nutritionLabel:
      selectedNutritionLabel = image
    }
  }
}
