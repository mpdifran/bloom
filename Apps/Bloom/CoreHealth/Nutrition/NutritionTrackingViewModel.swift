//
//  NutritionTrackingViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import SwiftUI
import SwiftData
import Combine
import BloomModel
import DataContainer
internal import TelemetryDeck
import BloomFoundation
import CoreNetwork

extension String {
  static let lastMealAutoUpdateDateKey = "NutritionTrackingViewModel.lastMealAutoUpdateDate"
}

private extension Bundle {
  var isAppExtension: Bool {
    bundlePath.hasSuffix(".appex")
  }
}

public struct DateState: Sendable {
  public let date: Date
  public let state: FoodLogDateState

  public init(date: Date, state: FoodLogDateState) {
    self.date = date
    self.state = state
  }
}

@MainActor
public final class NutritionTrackingViewModel: ObservableObject {
  public static let shared = NutritionTrackingViewModel()

  @Published public var date = Date.now
  @Published public var suggestedMeal = FoodItemLog.Meal.breakfast
  @Published public var dateStates = [DateState]()

  @Storage(key: .lastMealAutoUpdateDateKey, defaultValue: nil) var lastMealAutoUpdateDate: Date?

  private let foodLoggedContinuation: AsyncStream<Void>.Continuation
  public let foodLoggedStream: AsyncStream<Void>

  private init() {
    // Create AsyncStream for food logging events
    let (stream, continuation) = AsyncStream<Void>.makeStream()
    self.foodLoggedStream = stream
    self.foodLoggedContinuation = continuation

    updateMealForCurrentTime()
    Task {
      await refreshDateStates()
    }
  }
}

public extension NutritionTrackingViewModel {

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

  func updateNutrition(for dates: Set<Date>) async throws {
    for date in dates {
      try await HealthStoreModifier.shared.updateNutrition(for: date)
    }

    // Refresh date states in the background to avoid blocking
    Task {
      await refreshDateStates()
    }
  }

  func refreshDateStates() async {
    let dateRange = DateRange.window(around: .now, numberOfDays: 30)
    let modelActor = FoodItemLogModelActor.standard()

    var newDateStates = [DateState]()

    await withTaskGroup(of: DateState?.self) { group in
      Calendar.current.iterate(
        dateRange: dateRange,
        by: DateComponents(day: 1)
      ) { date in
        group.addTask {
          guard let logs = try? await modelActor.fetchLogs(for: date) else { return nil }

          let validMeals: Set<FoodItemLog.Meal> = [.breakfast, .lunch, .dinner]
          let meals = logs
            .filter { validMeals.contains($0.meal) }
            .map { $0.meal }
            .asSet()

          if meals.count == validMeals.count {
            return DateState(date: date, state: .complete)
          } else {
            let percentComplete = Double(meals.count) / Double(validMeals.count)
            return DateState(date: date, state: .inProgress(percentComplete))
          }
        }
      }

      for await state in group {
        if let state = state {
          newDateStates.append(state)
        }
      }
    }

    self.dateStates = newDateStates
  }
}

public extension NutritionTrackingViewModel {

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
    let modelContext = ModelContext(ContainerHolder.shared.container)
    return try modelContext.fetchOldestFoodItemLog()?.date
  }
}

// MARK: - Logging

public extension NutritionTrackingViewModel {

  @discardableResult
  func log(
    modelContext: ModelContext,
    name: String,
    imageData: Data?,
    numberOfServings: Double,
    foodItemServings: [FoodItemServingAmount],
    date: Date,
    meal: FoodItemLog.Meal
  ) async throws -> String {
    var dates = [Date]()
    let foodLogID = UUID().uuidString

    try modelContext.savingTransaction {
      let servings = try foodItemServings.map {
        let (modifiedDates, foodItem) = try upsertAndMerge(modelContext: modelContext, foodItem: $0.foodItem)

        dates.append(contentsOf: modifiedDates)

        return FoodItemServing(
          numberOfServings: $0.serving,
          foodItem: foodItem
        )
      }

      let logDate = calculateDate(for: meal, from: date)
      dates.append(logDate)

      let foodItemLog = FoodItemLog(
        id: foodLogID,
        name: name,
        date: logDate,
        meal: meal,
        numberOfServings: numberOfServings,
        imageData: imageData,
        foodItemServings: servings
      )

      modelContext.insert(foodItemLog)
    }

    try await updateNutrition(for: dates.asSet())

    if !Bundle.main.isAppExtension {
      TelemetryDeck.signal(
        "Logged Food Item",
        parameters: ["Meal": meal.rawValue],
        floatValue: Double(foodItemServings.count)
      )
    }

    // Track food item logs on the server (fire-and-forget)
    Task {
      let foodIDs = foodItemServings.map { $0.foodItem.id }
      try? await NetworkRequester.shared.trackFoodLog(foodIDs: foodIDs)
    }

    // Notify listeners that food was logged
    foodLoggedContinuation.yield()

    return foodLogID
  }

  /// Saves a Magic Scanner capture with processing state
  func logMagicScan(
    modelContext: ModelContext,
    processingIdentifier: AIFoodProcessingIdentifier,
    imageData: Data,
    contextText: String?,
    date: Date,
    meal: FoodItemLog.Meal
  ) {
    try? modelContext.savingTransaction {
      let logDate = calculateDate(for: meal, from: date)

      let foodItemLog = FoodItemLog(
        id: UUID().uuidString,
        name: nil,  // Will be set when processing completes
        date: logDate,
        meal: meal,
        numberOfServings: 1,
        imageData: imageData,
        foodItemServings: []  // Empty, populated after processing
      )

      // Set Magic Scanner fields
      foodItemLog.processingIdentifier = processingIdentifier.value
      foodItemLog.processingState = .pending
      foodItemLog.contextText = contextText?.isEmpty == false ? contextText : nil

      modelContext.insert(foodItemLog)
    }

    // Don't update HealthKit yet - wait until processing completes

    if !Bundle.main.isAppExtension {
      TelemetryDeck.signal("Magic Scan Save Item")
    }

    // Notify listeners that food was logged (pending state)
    foodLoggedContinuation.yield()
  }

  /// Saves a text-only AI food generation request with processing state
  func logTextOnlyMagicScan(
    modelContext: ModelContext,
    processingIdentifier: AIFoodProcessingIdentifier,
    contextText: String,
    date: Date,
    meal: FoodItemLog.Meal
  ) {
    try? modelContext.savingTransaction {
      let logDate = calculateDate(for: meal, from: date)

      let foodItemLog = FoodItemLog(
        id: UUID().uuidString,
        name: nil,  // Will be set when processing completes
        date: logDate,
        meal: meal,
        numberOfServings: 1,
        imageData: nil,  // No image for text-only generation
        foodItemServings: []  // Empty, populated after processing
      )

      // Set Magic Scanner fields
      foodItemLog.processingIdentifier = processingIdentifier.value
      foodItemLog.processingState = .pending
      foodItemLog.contextText = contextText

      modelContext.insert(foodItemLog)
    }

    // Don't update HealthKit yet - wait until processing completes

    if !Bundle.main.isAppExtension {
      TelemetryDeck.signal("AI Text Item Saved")
    }

    // Notify listeners that food was logged (pending state)
    foodLoggedContinuation.yield()
  }

  /// Retries a failed Magic Scanner upload
  func retryMagicScan(
    modelContext: ModelContext,
    foodItemLog: FoodItemLog
  ) async throws {
    guard let imageData = foodItemLog.imageData,
          let processingIdentifier = foodItemLog.processingIdentifier else {
      throw NSError(description: "Missing image data or processing identifier")
    }

    try modelContext.savingTransaction {
      // Reset to pending state
      foodItemLog.processingState = .pending
      foodItemLog.errorMessage = nil
    }

    // Re-upload image to backend
    do {
      _ = try await NetworkRequester.shared.uploadMagicScan(
        imageData: imageData,
        contextText: foodItemLog.contextText,
        processingIdentifier: AIFoodProcessingIdentifier(processingIdentifier)
      )
    } catch {
      try await failMagicScan(
        modelContext: modelContext,
        processingIdentifier: AIFoodProcessingIdentifier(processingIdentifier),
        errorMessage: "Failed to upload image"
      )
      throw error
    }

    if !Bundle.main.isAppExtension {
      TelemetryDeck.signal("Magic Scanner Retry")
    }
  }

  /// Marks a Magic Scanner upload as failed
  func failMagicScan(
    modelContext: ModelContext,
    processingIdentifier: AIFoodProcessingIdentifier,
    errorMessage: String
  ) async throws {
    // Find the food item log by processing identifier
    let identifierValue = processingIdentifier.value
    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate { $0.processingIdentifier == identifierValue }
    )

    guard let foodItemLog = try modelContext.fetch(descriptor).first else {
      return
    }

    try modelContext.savingTransaction {
      foodItemLog.processingState = .failed
      foodItemLog.errorMessage = errorMessage
    }

    if !Bundle.main.isAppExtension {
      TelemetryDeck.errorOccurred(
        id: "NutritionTrackingViewModel.failMagicScan",
        category: .thrownException,
        message: errorMessage
      )
      TelemetryDeck.signal("Magic Scanner Failed")
    }
  }

  /// Completes a Magic Scanner upload with results from backend
  func completeMagicScan(
    modelContext: ModelContext,
    processingIdentifier: AIFoodProcessingIdentifier,
    servings: [FoodItemServingAmount]
  ) async throws {
    // Find the food item log by processing identifier
    let identifierValue = processingIdentifier.value
    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate { $0.processingIdentifier == identifierValue }
    )

    guard let foodItemLog = try modelContext.fetch(descriptor).first else {
      return
    }

    var dates = [Date]()

    try modelContext.savingTransaction {
      // Convert FoodItemServingAmount to FoodItemServing
      var foodItemServings = [FoodItemServing]()

      for serving in servings {
        let (modifiedDates, foodItem) = try upsertAndMerge(modelContext: modelContext, foodItem: serving.foodItem)
        dates.append(contentsOf: modifiedDates)

        let foodItemServing = FoodItemServing(
          numberOfServings: serving.serving,
          foodItem: foodItem
        )
        modelContext.insert(foodItemServing)
        foodItemServings.append(foodItemServing)
      }

      // Update the food item log with servings
      foodItemLog.foodItemServings = foodItemServings
      foodItemLog.processingState = .completed
      foodItemLog.errorMessage = nil

      // Set name to first food item name
      if let firstServing = servings.first {
        foodItemLog.name = firstServing.foodItem.name
      }

      dates.append(foodItemLog.date)
    }

    // Update HealthKit
    try await updateNutrition(for: dates.asSet())

    if !Bundle.main.isAppExtension {
      TelemetryDeck.signal("Magic Scan Completed")
    }

    // Notify listeners that food was logged
    foodLoggedContinuation.yield()
  }

  /// Logs each serving as an individual `FoodItemLog`.
  func logIndividual(
    modelContext: ModelContext,
    foodItemServings: [FoodItemServingAmount],
    date: Date,
    meal: FoodItemLog.Meal
  ) async throws -> String? {
    var dates = [Date]()
    var firstLogID: String?

    try modelContext.savingTransaction {
      for serving in foodItemServings {
        let (modifiedDates, foodItem) = try upsertAndMerge(modelContext: modelContext, foodItem: serving.foodItem)

        dates.append(contentsOf: modifiedDates)
        let logDate = calculateDate(for: meal, from: date)
        dates.append(logDate)

        try modelContext.transaction {
          let foodItemServing = FoodItemServing(
            numberOfServings: serving.serving,
            foodItem: foodItem
          )
          modelContext.insert(foodItemServing)

          let logID = UUID().uuidString
          let foodItemLog = FoodItemLog(
            id: logID,
            name: nil,
            date: logDate,
            meal: meal,
            numberOfServings: 1,
            imageData: nil,
            foodItemServings: [foodItemServing]
          )
          modelContext.insert(foodItemLog)

          // Store the first log ID for return
          if firstLogID == nil {
            firstLogID = logID
          }
        }
      }
    }

    try await updateNutrition(for: dates.asSet())

    if !Bundle.main.isAppExtension {
      TelemetryDeck.signal(
        "Logged Food Item",
        parameters: ["Meal": meal.rawValue],
        floatValue: Double(foodItemServings.count)
      )
    }

    // Track food item logs on the server (fire-and-forget)
    Task {
      let foodIDs = foodItemServings.map { $0.foodItem.id }
      try? await NetworkRequester.shared.trackFoodLog(foodIDs: foodIDs)
    }

    // Notify listeners that food was logged
    foodLoggedContinuation.yield()

    return firstLogID
  }

  func log(
    modelContext: ModelContext,
    foodItem: FoodItem,
    date: Date,
    meal: FoodItemLog.Meal,
    numberOfServings: Double
  ) async throws -> String {
    let serving = FoodItemServingAmount(serving: numberOfServings, foodItem: foodItem)
    return try await logIndividual(
      modelContext: modelContext,
      foodItemServings: [serving],
      date: date,
      meal: meal
    ) ?? ""
  }
}

// MARK: - Delete Methods

public extension NutritionTrackingViewModel {

  func delete(
    modelContext: ModelContext,
    foodItemLogs: [FoodItemLog]
  ) async throws {
    var dates = Set<Date>()

    // Cancel any magic scan jobs that are in progress
    for foodItemLog in foodItemLogs {
      if let processingIdentifier = foodItemLog.processingIdentifier,
         let processingState = foodItemLog.processingState,
         (processingState == .pending || processingState == .processing) {
        // Fire and forget - don't block deletion if this fails
        Task {
          try? await NetworkRequester.shared.cancelMagicScan(
            processingIdentifier: AIFoodProcessingIdentifier(processingIdentifier)
          )
        }
      }
    }

    try modelContext.savingTransaction {
      for foodItemLog in foodItemLogs {
        dates.insert(foodItemLog.date)

        try modelContext.deleteByID(foodItemLog)
      }
    }

    try await updateNutrition(for: dates)
  }

  func delete(
    modelContext: ModelContext,
    foodItemServing: FoodItemServing
  ) async throws {
    var dates = Set<Date>()

    try modelContext.savingTransaction {
      if let date = foodItemServing.foodItemLog?.date {
        dates.insert(date)
      }

      try modelContext.deleteByID(foodItemServing)
    }

    try await updateNutrition(for: dates)
  }
}

// MARK: - Update Methods

public extension NutritionTrackingViewModel {

  func update(
    modelContext: ModelContext,
    foodItemLog: FoodItemLog,
    foodItemID: String,
    numberOfServings: Double,
    dateMeal: (Date, FoodItemLog.Meal)? = nil
  ) async throws {
    guard let localLog: FoodItemLog = try modelContext.existingModel(for: foodItemLog.persistentModelID) else {
      throw NSError(description: "There was a problem saving the changes.")
    }

    let oldDate = localLog.date

    try modelContext.savingTransaction {
      if
        let serving = foodItemLog.serving(for: foodItemID),
        let localServing: FoodItemServing = try modelContext.existingModel(for: serving.persistentModelID)
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

    try await updateNutrition(for: dates)
  }

  func update(
    modelContext: ModelContext,
    foodItemLog: FoodItemLog,
    numberOfServings: Double,
    foodItemNumberOfServings: [String: Double],
    date: Date,
    meal: FoodItemLog.Meal
  ) async throws {
    guard let localLog: FoodItemLog = try modelContext.existingModel(for: foodItemLog.persistentModelID) else {
      throw NSError(description: "There was a problem saving the changes.")
    }

    let oldDate = localLog.date

    try modelContext.savingTransaction {
      foodItemLog.numberOfServings = numberOfServings
      foodItemLog.date = date
      foodItemLog.meal = meal

      for serving in localLog.foodItemServings ?? [] {
        serving.numberOfServings = foodItemNumberOfServings[serving.id, default: 1]
      }
    }

    try await updateNutrition(for: [oldDate, date])
  }

  @available(*, deprecated, message: "Use update(foodItemLog:foodItemID:numberOfServings:dateMeal:) instead.")
  func update(
    modelContext: ModelContext,
    foodItem: FoodItemLog,
    numberOfServings: Double,
    date: Date,
    meal: FoodItemLog.Meal
  ) async throws {
    guard foodItem.hasSingleServing else {
      throw NSError(description: "This item cannot be edited at this time.")
    }

    guard
      let localLog: FoodItemLog = try modelContext.existingModel(for: foodItem.persistentModelID),
      let foodItemID = foodItem.firstFoodItemServing?.foodItem?.id
    else {
      throw NSError(description: "There was a problem saving the changes.")
    }

    let oldDate = localLog.date

    try modelContext.savingTransaction {
      if
        let serving = foodItem.serving(for: foodItemID),
        let localServing: FoodItemServing = try modelContext.existingModel(for: serving.persistentModelID)
      {
        localServing.numberOfServings = numberOfServings
      }

      localLog.date = calculateDate(for: meal, from: date)
      localLog.meal = meal
    }

    try await updateNutrition(for: [oldDate, date])
  }

  func changeMeal(
    modelContext: ModelContext,
    foodItemLog: FoodItemLog,
    to newMeal: FoodItemLog.Meal
  ) async throws {
    guard let localLog: FoodItemLog = try modelContext.existingModel(for: foodItemLog.persistentModelID) else {
      throw NSError(description: "There was a problem changing the meal.")
    }

    let oldDate = localLog.date
    let newDate = Calendar.current.startOfDay(for: oldDate)

    try modelContext.savingTransaction {
      localLog.meal = newMeal
      localLog.date = calculateDate(for: newMeal, from: newDate)
    }

    try await updateNutrition(for: [oldDate, newDate])

    TelemetryDeck.signal("Food Log Meal Changed", parameters: [
      "from_meal": foodItemLog.meal.rawValue,
      "to_meal": newMeal.rawValue
    ])
  }
}

// MARK: - FoodItemRecord Methods

public extension NutritionTrackingViewModel {

  /// Upserts the `foodItem` into the database if it exists, or creates a new record. If the upsert modifies the database record, a list of affected dates is returned.
  /// You can use these dates to re-sync HealthKit.
  /// - parameter modelContext: The ModelContext to use.
  /// - parameter foodItem: The food item to upsert.
  /// - returns: A list of dates that should be re-synced with HealthKit, and the FoodItemRecord.
  func upsertAndMerge(
    modelContext: ModelContext,
    foodItem: FoodItem
  ) throws -> ([Date], FoodItemRecord) {
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
}

// MARK: - MealRecords

public extension NutritionTrackingViewModel {

  func createMeal(
    modelContext: ModelContext,
    name: String,
    imageData: Data?,
    foodItemServings: [FoodItemServingAmount]
  ) async throws {
    guard name.isNotEmpty else {
      throw NSError(description: "Name must not be empty.")
    }
    guard foodItemServings.isNotEmpty else {
      throw NSError(description: "At least one food item must be added.")
    }

    var datesToUpdate = Set<Date>()

    try modelContext.savingTransaction {

      var mealItemRecords = [MealItemRecord]()

      for foodItemServing in foodItemServings {
        let (dates, foodItemRecord) = try upsertAndMerge(
          modelContext: modelContext,
          foodItem: foodItemServing.foodItem
        )

        let numberOfServings = foodItemServing.serving

        let mealItemRecord = MealItemRecord(
          numberOfServings: numberOfServings,
          foodItem: foodItemRecord
        )
        modelContext.insert(mealItemRecord)
        mealItemRecords.append(mealItemRecord)
        datesToUpdate.formUnion(dates)
      }

      let meal = MealRecord(
        name: name,
        imageData: imageData,
        items: mealItemRecords
      )

      modelContext.insert(meal)
    }

    try await updateNutrition(for: datesToUpdate)
  }

  func updateMeal(
    modelContext: ModelContext,
    mealRecord: MealRecord,
    name: String,
    imageData: Data?,
    foodItemServings: [FoodItemServingAmount]
  ) async throws {
    guard name.isNotEmpty else {
      throw NSError(description: "Name must not be empty.")
    }
    guard foodItemServings.isNotEmpty else {
      throw NSError(description: "At least one food item must be added.")
    }

    var datesToUpdate = Set<Date>()

    try modelContext.savingTransaction {
      mealRecord.name = name
      mealRecord.imageData = imageData

      // Create new meal items, or fetch existing ones.
      var mealItems = [MealItemRecord]()
      for foodItemServing in foodItemServings {
        let numberOfServings = foodItemServing.serving
        let foodItem = foodItemServing.foodItem

        if let existingMealItem = mealRecord.items?.first(where: { $0.foodItem?.id == foodItem.id.value }) {
          existingMealItem.numberOfServings = numberOfServings
          mealItems.append(existingMealItem)
        } else {
          let (dates, foodItemRecord) = try upsertAndMerge(
            modelContext: modelContext,
            foodItem: foodItem
          )
          let mealItemRecord = MealItemRecord(
            numberOfServings: numberOfServings,
            foodItem: foodItemRecord
          )
          modelContext.insert(mealItemRecord)
          mealItems.append(mealItemRecord)
          datesToUpdate.formUnion(dates)
        }
      }

      // Delete old meal items.
      let mealItemsToDelete = mealRecord.items?.filter { item in
        !mealItems.contains(where: { $0.id == item.id })
      }
      mealItemsToDelete?.forEach({ modelContext.delete($0) })

      mealRecord.items = mealItems
    }

    try await updateNutrition(for: datesToUpdate)
  }

  func log(
    modelContext: ModelContext,
    mealRecord: MealRecord,
    numberOfServings: Double,
    date: Date,
    meal: FoodItemLog.Meal
  ) async throws {
    guard let items = mealRecord.items else {
      throw NSError(description: "This meal has no food items.")
    }

    var dates = [Date]()

    try modelContext.savingTransaction {
      let servings = items.map { item in
        let serving = FoodItemServing(
          numberOfServings: item.numberOfServings,
          foodItem: item.foodItem
        )
        modelContext.insert(serving)
        return serving
      }

      let logDate = calculateDate(for: meal, from: date)
      dates.append(logDate)

      let foodItemLog = FoodItemLog(
        id: UUID().uuidString,
        name: mealRecord.name,
        date: logDate,
        meal: meal,
        numberOfServings: numberOfServings,
        imageData: mealRecord.imageData,
        foodItemServings: servings
      )
      foodItemLog.mealItem = mealRecord
      modelContext.insert(foodItemLog)
    }

    try await updateNutrition(for: dates.asSet())

    if !Bundle.main.isAppExtension {
      TelemetryDeck.signal(
        "Logged Food Item",
        parameters: ["Meal": meal.rawValue],
        floatValue: Double(items.count)
      )

      TelemetryDeck.signal(
        "Logged Meal",
        parameters: ["Meal": meal.rawValue],
        floatValue: Double(items.count)
      )
    }

    // Notify listeners that food was logged
    foodLoggedContinuation.yield()
  }
}

// MARK: - Duplicate Methods

public extension NutritionTrackingViewModel {

  func duplicate(
    modelContext: ModelContext,
    foodItemLog: FoodItemLog,
    toDate date: Date,
    toMeal meal: FoodItemLog.Meal
  ) async throws {
    var dates = [Date]()

    try modelContext.savingTransaction {
      // Create new servings from the existing ones
      var newServings: [FoodItemServing] = []

      if let existingServings = foodItemLog.foodItemServings {
        for serving in existingServings {
          if let foodItem = serving.foodItem {
            let newServing = FoodItemServing(
              numberOfServings: serving.numberOfServings,
              foodItem: foodItem
            )
            modelContext.insert(newServing)
            newServings.append(newServing)
          }
        }
      }

      let logDate = calculateDate(for: meal, from: date)
      dates.append(logDate)

      // Create the duplicate food log
      let duplicatedLog = FoodItemLog(
        id: UUID().uuidString,
        name: foodItemLog.name,
        date: logDate,
        meal: meal,
        numberOfServings: foodItemLog.numberOfServings,
        imageData: foodItemLog.imageData,
        foodItemServings: newServings
      )

      // Copy meal item reference if it exists
      if let mealItem = foodItemLog.mealItem {
        duplicatedLog.mealItem = mealItem
      }

      modelContext.insert(duplicatedLog)
    }

    try await updateNutrition(for: dates.asSet())

    if !Bundle.main.isAppExtension {
      TelemetryDeck.signal(
        "Duplicated Food Log",
        parameters: ["Meal": meal.rawValue]
      )
    }

    // Notify listeners that food was logged
    foodLoggedContinuation.yield()
  }
}

// MARK: - Private Methods

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
