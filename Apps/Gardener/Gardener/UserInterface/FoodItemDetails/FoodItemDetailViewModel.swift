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
  private var initialFoodItem: AdminFoodItemRecord

  private let foodStore: BaseFoodStore

  @Published var packagingImage: URL?
  @Published var nutritionLabel: URL?

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
    await foodStore.update(foodItem)
  }

  func delete() async {
    await foodStore.delete(foodItem)
  }
}
