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

  // TODO: Zach - fetch images from S3
  let packagingImage = URL(string: "https://picsum.photos/seed/package/200/300")!
  let nutritionLabel = URL(string: "https://picsum.photos/seed/label/200/300")!

  init(foodItem: AdminFoodItemRecord) {
    self.foodItem = foodItem
    self.initialFoodItem = foodItem
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
