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
import BloomFoundation

extension String {
  static let lastMealAutoUpdateDateKey = "NutritionTrackingViewModel.lastMealAutoUpdateDate"
}

@MainActor
final class NutritionTrackingViewModel: ObservableObject {
  static let shared = NutritionTrackingViewModel()

  @Published var date = Date.now
  @Published var suggestedMeal = FoodItemLog.Meal.breakfast

  @Storage(key: .lastMealAutoUpdateDateKey, defaultValue: nil) var lastMealAutoUpdateDate: Date?

  private let modelContext = ModelContext(ContainerHolder.shared.container)

  private init() {
    updateMealForCurrentTime()
  }
}

extension NutritionTrackingViewModel {

  func updateMealForCurrentTime() {
    if let lastUpdateDate = lastMealAutoUpdateDate {
      guard Date.now.timeIntervalSince(lastUpdateDate) > 60 * 5 else {
        return
      }
    }

    date = .now
    let hour = Calendar.current.component(.hour, from: date)

    switch hour {
    case 6 ..< 11:
      suggestedMeal = .breakfast
    case 11 ..< 16:
      suggestedMeal = .lunch
    case 16 ..< 24:
      suggestedMeal = .dinner
    default:
      return
    }

    lastMealAutoUpdateDate = .now
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
      advanceDay()
    @unknown default:
      break
    }
  }

  /// Reverses the suggested meal by one meal. If needed, the day will reverse as well.
  func reverseTimeWindow() {
    switch suggestedMeal {
    case .breakfast:
      suggestedMeal = .snack
      reverseDay()
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

  func advanceDay() {
    date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
  }

  func reverseDay() {
    date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
  }
}

extension NutritionTrackingViewModel {

  func log(
    foodItemServings: [FoodItemServing],
    date: Date,
    meal: FoodItemLog.Meal
  ) async throws {
    var dates = [Date]()
    try modelContext.transaction {
      for serving in foodItemServings {
        let dbFoodItem: FoodItemRecord
        let existingFoodItems = try modelContext.fetchAllFoodItem(for: serving.foodItem.id.value)
        if existingFoodItems.isNotEmpty, let foodItem = try modelContext.merge(existingFoodItems) {
          dbFoodItem = foodItem
          if dbFoodItem.apply(foodItem: serving.foodItem) {
            // If we updated the food item properties, we should resync every day it was logged.
            dates.append(contentsOf: dbFoodItem.logDates())
          }
        } else {
          dbFoodItem = FoodItemRecord(foodItem: serving.foodItem)
          modelContext.insert(dbFoodItem)
        }

        let logDate = calculateDate(for: meal, from: date)
        dates.append(logDate)

        let foodItemLog = FoodItemLog(
          id: UUID().uuidString,
          date: logDate,
          meal: meal,
          numberOfServings: serving.serving,
          foodItem: dbFoodItem
        )

        modelContext.insert(foodItemLog)
      }
    }

    for updateDate in dates {
      try await HealthStoreModifier.shared.updateNutrition(for: updateDate)
    }

    TelemetryDeck.signal(
      "Logged Food Item",
      parameters: ["Meal": meal.rawValue],
      floatValue: Double(foodItemServings.count)
    )
  }

  func log(
    foodItem: FoodItem,
    date: Date,
    meal: FoodItemLog.Meal,
    numberOfServings: Double
  ) async throws {
    let serving = FoodItemServing(serving: numberOfServings, foodItem: foodItem)
    try await log(
      foodItemServings: [serving],
      date: date,
      meal: meal
    )
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
    localLog.date = calculateDate(for: meal, from: date)
    localLog.meal = meal

    try modelContext.save()
    
    try await HealthStoreModifier.shared.updateNutrition(for: oldDate)
    try await HealthStoreModifier.shared.updateNutrition(for: date)
  }
}

extension NutritionTrackingViewModel {

  nonisolated func reSyncNutritionToHealthKit() async throws {
    guard let earliestLog = try await earliestLogDate() else { return }

    let dateRange = DateRange(earliestLog, Date())

    await Calendar.current.aysncIterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
      do {
        try await HealthStoreModifier.shared.updateNutrition(for: date)
      } catch {
        print(error)
      }
    }
  }

  private func earliestLogDate() throws -> Date? {
    try modelContext.fetchOldestFoodItemLog()?.date
  }
}

private extension NutritionTrackingViewModel {

  func calculateDate(for meal: FoodItemLog.Meal, from date: Date) -> Date {
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
