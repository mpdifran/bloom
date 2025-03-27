//
//  ModelContext+Nutrition.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-22.
//

import SwiftUI
import SwiftData
import BloomModel
import DataContainer
import TelemetryDeck
import BloomFoundation

// MARK: - Logging

extension ModelContext {

  func log(
    name: String,
    image: UIImage?,
    numberOfServings: Double,
    foodItemServings: [FoodItemServingAmount],
    date: Date,
    meal: FoodItemLog.Meal
  ) throws {
    var dates = [Date]()

    try savingTransaction {
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

      insert(foodItemLog)
    }

    Task {
      try await NutritionTrackingViewModel.shared.updateNutrition(for: dates.asSet())
    }

    TelemetryDeck.signal(
      "Logged Food Item",
      parameters: ["Meal": meal.rawValue],
      floatValue: Double(foodItemServings.count)
    )
  }

  /// Logs each serving as an individual `FoodItemLog`.
  func logIndividual(
    foodItemServings: [FoodItemServingAmount],
    date: Date,
    meal: FoodItemLog.Meal
  ) throws {
    var dates = [Date]()

    try savingTransaction {
      for serving in foodItemServings {
        let (modifiedDates, foodItem) = try upsertAndMerge(foodItem: serving.foodItem)

        dates.append(contentsOf: modifiedDates)
        let logDate = calculateDate(for: meal, from: date)
        dates.append(logDate)

        try transaction {
          let foodItemServing = FoodItemServing(
            numberOfServings: serving.serving,
            foodItem: foodItem
          )
          insert(foodItemServing)

          let foodItemLog = FoodItemLog(
            id: UUID().uuidString,
            name: nil,
            date: logDate,
            meal: meal,
            numberOfServings: 1,
            imageData: nil,
            foodItemServings: [foodItemServing]
          )
          insert(foodItemLog)
        }
      }
    }

    Task {
      try await NutritionTrackingViewModel.shared.updateNutrition(for: dates.asSet())
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
  ) throws {
    let serving = FoodItemServingAmount(serving: numberOfServings, foodItem: foodItem)
    try logIndividual(
      foodItemServings: [serving],
      date: date,
      meal: meal
    )
  }
}

// MARK: - Delete Methods

extension ModelContext {

  func delete(foodItemLogs: [FoodItemLog]) throws {
    var dates = Set<Date>()

    try savingTransaction {
      for foodItemLog in foodItemLogs {
        dates.insert(foodItemLog.date)

        try deleteByID(foodItemLog)
      }
    }

    Task {
      try await NutritionTrackingViewModel.shared.updateNutrition(for: dates)
    }
  }

  func delete(foodItemServing: FoodItemServing) throws {
    var dates = Set<Date>()

    try savingTransaction {
      if let date = foodItemServing.foodItemLog?.date {
        dates.insert(date)
      }

      try deleteByID(foodItemServing)
    }

    Task {
      try await NutritionTrackingViewModel.shared.updateNutrition(for: dates)
    }
  }
}

// MARK: - Update Methods

extension ModelContext {

  func update(
    foodItemLog: FoodItemLog,
    foodItemID: String,
    numberOfServings: Double,
    dateMeal: (Date, FoodItemLog.Meal)? = nil
  ) throws {
    guard let localLog: FoodItemLog = try existingModel(for: foodItemLog.persistentModelID) else {
      throw NSError(description: "There was a problem saving the changes.")
    }

    let oldDate = localLog.date

    try savingTransaction {
      if
        let serving = foodItemLog.serving(for: foodItemID),
        let localServing: FoodItemServing = try existingModel(for: serving.persistentModelID)
      {
        localServing.numberOfServings = numberOfServings
      }

      if let (date, meal) = dateMeal {
        localLog.date = calculateDate(for: meal, from: date)
        localLog.meal = meal
      }
    }

    var dates = Set<Date>([oldDate])
    if let (date, _) = dateMeal {
      dates.insert(date)
    }

    Task {
      try await NutritionTrackingViewModel.shared.updateNutrition(for: dates)
    }
  }

  func update(
    foodItemLog: FoodItemLog,
    numberOfServings: Double,
    foodItemNumberOfServings: [String: Double],
    date: Date,
    meal: FoodItemLog.Meal
  ) throws {
    guard let localLog: FoodItemLog = try existingModel(for: foodItemLog.persistentModelID) else {
      throw NSError(description: "There was a problem saving the changes.")
    }

    let oldDate = localLog.date

    try savingTransaction {
      foodItemLog.numberOfServings = numberOfServings
      foodItemLog.date = date
      foodItemLog.meal = meal

      for serving in localLog.foodItemServings ?? [] {
        serving.numberOfServings = foodItemNumberOfServings[serving.id, default: 1]
      }
    }

    Task {
      try await NutritionTrackingViewModel.shared.updateNutrition(for: [oldDate, date])
    }
  }

  @available(*, deprecated, message: "Use update(foodItemLog:foodItemID:numberOfServings:dateMeal:) instead.")
  func update(
    foodItem: FoodItemLog,
    numberOfServings: Double,
    date: Date,
    meal: FoodItemLog.Meal
  ) throws {
    guard foodItem.hasSingleServing else {
      throw NSError(description: "This item cannot be edited at this time.")
    }

    guard
      let localLog: FoodItemLog = try existingModel(for: foodItem.persistentModelID),
      let foodItemID = foodItem.firstFoodItemServing?.foodItem?.id
    else {
      throw NSError(description: "There was a problem saving the changes.")
    }

    let oldDate = localLog.date

    try savingTransaction {
      if
        let serving = foodItem.serving(for: foodItemID),
        let localServing: FoodItemServing = try existingModel(for: serving.persistentModelID)
      {
        localServing.numberOfServings = numberOfServings
      }

      localLog.date = calculateDate(for: meal, from: date)
      localLog.meal = meal
    }

    Task {
      try await NutritionTrackingViewModel.shared.updateNutrition(for: [oldDate, date])
    }
  }
}

// MARK: - FoodItemRecord Methods

extension ModelContext {

  /// Upserts the `foodItem` into the database if it exists, or creates a new record. If the upsert modifies the database record, a list of affected dates is returned.
  /// You can use these dates to re-sync HealthKit.
  /// - parameter foodItem: The food item to upsert.
  /// - returns: A list of dates that should be re-synced with HealthKit, and the FoodItemRecord.
  func upsertAndMerge(foodItem: FoodItem) throws -> ([Date], FoodItemRecord) {
    let existingFoodItems = try fetchAllFoodItems(for: foodItem.id.value)
    if existingFoodItems.isNotEmpty, let dbFoodItem = try merge(existingFoodItems) {
      var dates = [Date]()
      if dbFoodItem.apply(foodItem: foodItem) {
        // If we updated the food item properties, we should resync every day it was logged.
        dates.append(contentsOf: dbFoodItem.logDates())
      }
      return (dates, dbFoodItem)
    } else {
      let insertedFoodItem = FoodItemRecord(foodItem: foodItem)
      insert(insertedFoodItem)
      return ([], insertedFoodItem)
    }
  }
}

// MARK: - Private Methods

private extension ModelContext {

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
