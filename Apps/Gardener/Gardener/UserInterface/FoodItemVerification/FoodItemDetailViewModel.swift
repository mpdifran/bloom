//
//  FoodItemDetailViewModel.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import BloomModel
import Foundation

@MainActor
final class FoodItemDetailViewModel: ObservableObject {

  @Published var foodItem: AdminFoodItemRecord
  private var initialFoodItem: AdminFoodItemRecord

  @Published var packagingImage: URL?
  @Published var nutritionLabel: URL?

  init(foodItem: AdminFoodItemRecord) {
    self.foodItem = foodItem
    self.initialFoodItem = foodItem

    packagingImage = foodItem.packagingImage
    nutritionLabel = foodItem.nutritionLabelImage
  }
}

extension FoodItemDetailViewModel {
  func propertyChanged<T: Equatable>(_ keyPath: KeyPath<AdminFoodItemRecord, T?>) -> Bool {
    foodItem[keyPath: keyPath] != initialFoodItem[keyPath: keyPath]
  }

  func verify() async {
    // Mark the log as verified
  }
}
