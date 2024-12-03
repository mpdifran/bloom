//
//  NutritionTrackingViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import SwiftUI
import SwiftData
import BloomModel
import DataContainer
import TelemetryDeck

@Observable @MainActor
final class NutritionTrackingViewModel {
  static let shared = NutritionTrackingViewModel()

  var date = Date.now
  var suggestedMeal = FoodItemLog.Meal.breakfast

  private let modelContext = ModelContext(ContainerHolder.shared.container)

  private init() {
    updateMealForCurrentTime()
  }
}

extension NutritionTrackingViewModel {

  func updateMealForCurrentTime() {
    date = .now
    let hour = Calendar.current.component(.hour, from: date)

    switch hour {
    case 6 ..< 10:
      suggestedMeal = .breakfast
    case 11 ..< 13:
      suggestedMeal = .lunch
    case 17 ..< 20:
      suggestedMeal = .dinner
    default:
      break
    }
  }

  /// Advances the suggested meal by one meal. If needed, the day will advance as well.
  func advanceTimeWindow() {
    switch suggestedMeal {
    case .breakfast:
      suggestedMeal = .lunch
    case .lunch:
      suggestedMeal = .dinner
    case .dinner:
      suggestedMeal = .snack
    case .snack:
      suggestedMeal = .breakfast
      date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
    @unknown default:
      break
    }
  }

  /// Reverses the suggested meal by one meal. If needed, the day will reverse as well.
  func reverseTimeWindow() {
    switch suggestedMeal {
    case .breakfast:
      suggestedMeal = .snack
      date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
    case .lunch:
      suggestedMeal = .breakfast
    case .dinner:
      suggestedMeal = .lunch
    case .snack:
      suggestedMeal = .dinner
    @unknown default:
      break
    }
  }
}

extension NutritionTrackingViewModel {

  func log(foodItemServings: [FoodItemServing], meal: FoodItemLog.Meal) async throws {
    try modelContext.transaction {
      for serving in foodItemServings {
        let dbFoodItem: FoodItemRecord
        if let existingFoodItem = try modelContext.fetchFoodItem(for: serving.foodItem.id.value) {
          dbFoodItem = existingFoodItem
          dbFoodItem.apply(foodItem: serving.foodItem)
        } else {
          dbFoodItem = FoodItemRecord(foodItem: serving.foodItem)
          modelContext.insert(dbFoodItem)
        }

        let foodItemLog = FoodItemLog(
          id: UUID().uuidString,
          date: date(for: meal),
          meal: meal,
          numberOfServings: serving.serving,
          foodItem: dbFoodItem
        )

        modelContext.insert(foodItemLog)
      }
    }

    try await HealthStoreModifier.shared.updateNutrition(for: date)

    TelemetryDeck.signal(
      "Logged Food Item",
      parameters: ["Meal" : meal.rawValue],
      floatValue: Double(foodItemServings.count)
    )
  }

  func log(
    foodItem: FoodItem,
    meal: FoodItemLog.Meal,
    numberOfServings: Double
  ) async throws {
    let serving = FoodItemServing(serving: numberOfServings, foodItem: foodItem)
    try await log(foodItemServings: [serving], meal: meal)
  }

  func delete(foodItemLogs: [FoodItemLog]) async throws {
    var dates = Set<Date>()

    try? modelContext.transaction {
      for foodItemLog in foodItemLogs {
        dates.insert(foodItemLog.date)

        try modelContext.deleteByID(foodItemLog)
      }
    }

    for date in dates {
      try await HealthStoreModifier.shared.updateNutrition(for: date)
    }
  }

  func update(
    foodItem: FoodItemLog,
    numberOfServings: Double,
    date: Date,
    meal: FoodItemLog.Meal
  ) async throws {
    guard let localLog: FoodItemLog = try modelContext.existingModel(for: foodItem.persistentModelID) else {
      throw NSError(description: "There was a problem saving the changes.")
    }

    let oldDate = localLog.date

    localLog.numberOfServings = numberOfServings
    localLog.date = self.date(for: meal)
    localLog.meal = meal

    try modelContext.save()
    
    try await HealthStoreModifier.shared.updateNutrition(for: oldDate)
    try await HealthStoreModifier.shared.updateNutrition(for: date)
  }
}

private extension NutritionTrackingViewModel {

  func date(for meal: FoodItemLog.Meal) -> Date {
    switch meal {
    case .breakfast:
      Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
    case .lunch:
      Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
    case .dinner:
      Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: date) ?? date
    case .snack:
      Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date
    @unknown default:
      date
    }
  }
}
