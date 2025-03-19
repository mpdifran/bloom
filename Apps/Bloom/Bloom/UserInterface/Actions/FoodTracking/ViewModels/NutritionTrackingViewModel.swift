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

  /// Logs as a single ``FoodItemLog`` with multiple ``FoodItemServing``s, applying the name and image.
  func logMeal(
    name: String,
    image: UIImage?,
    numberOfServings: Double,
    foodItemServings: [FoodItemServingAmount],
    date: Date,
    meal: FoodItemLog.Meal
  ) async throws {
    var dates = [Date]()

    try modelContext.transaction {
      let servings = try foodItemServings.map {
        let (modifiedDates, foodItem) = try upsertAndMerge(foodItem: $0.foodItem)

        dates.append(contentsOf: modifiedDates)

        return FoodItemServing(
          numberOfServings: $0.serving,
          foodItem: foodItem
        )
      }

      let logDate = calculateDate(for: meal, from: date)
      dates.append(logDate)

      let foodItemLog = FoodItemLog(
        id: UUID().uuidString,
        name: name,
        date: logDate,
        meal: meal,
        numberOfServings: numberOfServings,
        imageData: image?.pngData(),
        foodItemServings: servings
      )

      modelContext.insert(foodItemLog)
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

  /// Logs each serving as an individual `FoodItemLog`.
  func log(
    foodItemServings: [FoodItemServingAmount],
    date: Date,
    meal: FoodItemLog.Meal
  ) async throws {
    var dates = [Date]()
    try modelContext.transaction {
      for serving in foodItemServings {
        let (modifiedDates, foodItem) = try upsertAndMerge(foodItem: serving.foodItem)

        dates.append(contentsOf: modifiedDates)
        let logDate = calculateDate(for: meal, from: date)
        dates.append(logDate)

        let foodItemLog = FoodItemLog(
          id: UUID().uuidString,
          name: nil,
          date: logDate,
          meal: meal,
          numberOfServings: serving.serving,
          imageData: nil,
          foodItem: foodItem
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
    let serving = FoodItemServingAmount(serving: numberOfServings, foodItem: foodItem)
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

    await Calendar.current.asyncIterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
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

  /// Upserts the `foodItem` into the database if it exists, or creates a new record. If the upsert modifies the database record, a list of affected dates is returned.
  /// You can use these dates to re-sync HealthKit.
  /// - parameter foodItem: The food item to upsert.
  /// - returns: A list of dates that should be re-synced with HealthKit, and the FoodItemRecord.
  func upsertAndMerge(foodItem: FoodItem) throws -> ([Date], FoodItemRecord) {
    let existingFoodItems = try modelContext.fetchAllFoodItems(for: foodItem.id.value)
    if existingFoodItems.isNotEmpty, let dbFoodItem = try modelContext.merge(existingFoodItems) {
      var dates = [Date]()
      if dbFoodItem.apply(foodItem: foodItem) {
        // If we updated the food item properties, we should resync every day it was logged.
        dates.append(contentsOf: dbFoodItem.logDates())
      }
      return (dates, dbFoodItem)
    } else {
      let insertedFoodItem = FoodItemRecord(foodItem: foodItem)
      modelContext.insert(insertedFoodItem)
      return ([], insertedFoodItem)
    }
  }

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
