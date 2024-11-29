//
//  FoodItemDetailViewModel.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import Foundation

@MainActor
final class FoodItemDetailViewModel: ObservableObject {

  @Published var name: String
  @Published var brandName: String
  @Published var calories: String

  private let foodItem: FoodItem

  init(foodItem: FoodItem) {
    self.foodItem = foodItem

    name = foodItem.name
    brandName = foodItem.brandName
    calories = String(format: "%.2f", foodItem.calories ?? 0)
  }
}

extension FoodItemDetailViewModel {
  func fix() async {
    // Update the log with new inputs
  }

  func verify() async {
    // Mark the log as verified
  }
}
