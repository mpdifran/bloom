//
//  WatchFoodSyncer.swift
//  Bloom
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import BloomFoundation
import DataContainer
import SwiftData

/// Syncs frequent foods to the Apple Watch for quick logging
@MainActor
final class WatchFoodSyncer {
  static let shared = WatchFoodSyncer()

  private let modelActor = FoodItemLogModelActor.standard()

  private init() {}

  /// Syncs foods and meals to watch
  func syncToWatch() async {
    #if os(iOS)
    do {
      let watchData = try await fetchAllFoodData()

      guard let data = try? JSONEncoder.watch.encode(watchData) else {
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

  private func fetchAllFoodData() async throws -> WatchFoodData {
    // Fetch frequent foods for each meal in parallel
    async let breakfastFoods = fetchFrequentFoods(for: .breakfast)
    async let lunchFoods = fetchFrequentFoods(for: .lunch)
    async let dinnerFoods = fetchFrequentFoods(for: .dinner)
    async let snackFoods = fetchFrequentFoods(for: .snack)

    // Fetch recent foods for each meal in parallel
    async let recentBreakfastFoods = fetchRecentFoods(for: .breakfast)
    async let recentLunchFoods = fetchRecentFoods(for: .lunch)
    async let recentDinnerFoods = fetchRecentFoods(for: .dinner)
    async let recentSnackFoods = fetchRecentFoods(for: .snack)

    // Fetch saved meals
    async let meals = fetchMeals()

    return WatchFoodData(
      breakfastFoods: try await breakfastFoods,
      lunchFoods: try await lunchFoods,
      dinnerFoods: try await dinnerFoods,
      snackFoods: try await snackFoods,
      recentBreakfastFoods: try await recentBreakfastFoods,
      recentLunchFoods: try await recentLunchFoods,
      recentDinnerFoods: try await recentDinnerFoods,
      recentSnackFoods: try await recentSnackFoods,
      meals: try await meals,
      lastUpdated: Date()
    )
  }

  private func fetchFrequentFoods(for meal: FoodItemLog.Meal) async throws -> [WatchFoodItem] {
    let foodDTOs = try await modelActor.fetchFrequentLogs(for: meal)
    return Array(foodDTOs.prefix(20)).map { convertToWatchFoodItem($0) }
  }

  private func fetchRecentFoods(for meal: FoodItemLog.Meal) async throws -> [WatchFoodItem] {
    let foodDTOs = try await modelActor.fetchRecentLogs(for: meal)
    return Array(foodDTOs.prefix(20)).map { convertToWatchFoodItem($0) }
  }

  private func convertToWatchFoodItem(_ dto: FoodItemDTO) -> WatchFoodItem {
    WatchFoodItem(
      id: dto.id,
      name: dto.name,
      brandName: dto.brandName.isEmpty ? nil : dto.brandName,
      calories: dto.calories,
      protein: dto.protein,
      carbs: dto.carbohydrates,
      fat: dto.fat,
      servingName: {
        var result = dto.servingName ?? "1 serving"
        if let value = dto.servingValue, let unit = dto.servingUnitString {
          result += " (\(value.formatted()) \(unit))"
        }
        return result
      }()
    )
  }

  private func fetchMeals() async throws -> [WatchMealItem] {
    let context = ContainerHolder.shared.createContext()
    let descriptor = FetchDescriptor<MealRecord>()
    let mealRecords = try context.fetch(descriptor)

    return mealRecords.map { record in
      WatchMealItem(
        id: record.id,
        name: record.name,
        calories: record.totalCalories,
        protein: record.totalProtein,
        carbs: record.totalCarbs,
        fat: record.totalFat
      )
    }
  }
}
