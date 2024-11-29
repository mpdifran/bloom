//
//  FoodItemVerificationViewModel.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import Foundation

@MainActor
final class FoodItemVerificationViewModel: ObservableObject {
  static let shared = FoodItemVerificationViewModel()

  @Published var foodItems: [FoodItem] = []
}

extension FoodItemVerificationViewModel {
  func loadItems() async {
    // This will be from the network.

    foodItems = [
      .init(
        id: UUID().uuidString,
        name: "Hot dog",
        brandName: "Franks",
        nutritionLabel: URL(string: "https://picsum.photos/seed/hotdogLabel/200/300"),
        packagingImage: URL(string: "https://picsum.photos/seed/hotdogPackage/200/300"),
        calories: 150
      ),
      .init(
        id: UUID().uuidString,
        name: "Burger",
        brandName: "McDonalds",
        nutritionLabel: URL(string: "https://picsum.photos/seed/burgerLabel/200/300"),
        packagingImage: URL(string: "https://picsum.photos/seed/burgerPackage/200/300"),
        calories: 200
      ),
      .init(
        id: UUID().uuidString,
        name: "Apple",
        brandName: "Tree",
        nutritionLabel: URL(string: "https://picsum.photos/seed/appleLabel/200/300"),
        packagingImage: URL(string: "https://picsum.photos/seed/applePackage/200/300"),
        calories: 1500
      ),
    ]
  }
}

struct FoodItem: Hashable, Identifiable {
  let id: String
  let name: String
  let brandName: String
  let nutritionLabel: URL?
  let packagingImage: URL?
  let calories: Double?
  // Add more fields here...
}
