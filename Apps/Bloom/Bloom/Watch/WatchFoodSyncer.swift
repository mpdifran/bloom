//
//  WatchFoodSyncer.swift
//  Bloom
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import BloomFoundation
import DataContainer

/// Syncs frequent foods to the Apple Watch for quick logging
@MainActor
final class WatchFoodSyncer {
  static let shared = WatchFoodSyncer()

  private let modelActor = FoodItemLogModelActor.standard()

  private init() {}

  /// Syncs frequent foods to watch
  func syncToWatch() async {
    #if os(iOS)
    do {
      let watchData = try await fetchFrequentFoodsPerMeal()

      guard let data = try? JSONEncoder().encode(watchData) else {
        print("Failed to encode watch food data")
        return
      }

      try await WatchChannel.shared.updateApplicationContext(
        key: WatchChannel.foodDataKey,
        data: data
      )
    } catch {
      print("Failed to sync foods to watch: \(error)")
    }
    #endif
  }

  private func fetchFrequentFoodsPerMeal() async throws -> WatchFoodData {
    // Fetch frequent foods for each meal in parallel
    async let breakfastFoods = fetchFoods(for: .breakfast)
    async let lunchFoods = fetchFoods(for: .lunch)
    async let dinnerFoods = fetchFoods(for: .dinner)
    async let snackFoods = fetchFoods(for: .snack)

    return WatchFoodData(
      breakfastFoods: try await breakfastFoods,
      lunchFoods: try await lunchFoods,
      dinnerFoods: try await dinnerFoods,
      snackFoods: try await snackFoods,
      lastUpdated: Date()
    )
  }

  private func fetchFoods(for meal: FoodItemLog.Meal) async throws -> [WatchFoodItem] {
    let foodDTOs = try await modelActor.fetchFrequentLogs(for: meal)

    // Limit to top 20 for watch display
    return Array(foodDTOs.prefix(20)).map { dto in
      WatchFoodItem(
        id: dto.id,
        name: dto.name,
        brandName: dto.brandName.isEmpty ? nil : dto.brandName,
        calories: dto.calories,
        protein: dto.protein,
        carbs: dto.carbohydrates,
        fat: dto.fat,
        servingName: dto.servingName ?? "1 serving"
      )
    }
  }
}
