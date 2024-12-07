//
//  FoodItemVerificationViewModel.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import BloomModel
import Foundation

@MainActor
final class FoodItemVerificationViewModel: ObservableObject {
  static let shared = FoodItemVerificationViewModel()

  @Published var foodItems: [AdminFoodItemRecord] = []

  private let service = NetworkStack.shared
}

extension FoodItemVerificationViewModel {
  func loadItems() async {
    do {
      let response = try await service.getUnverifiedFoodRecords(limit: 50)
      foodItems = response.foodItemRecords
    } catch {
      print("Error fetching unverified food records: \(error)")
    }
  }
}
