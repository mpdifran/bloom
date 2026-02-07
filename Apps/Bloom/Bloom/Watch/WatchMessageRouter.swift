//
//  WatchMessageRouter.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-30.
//

import Foundation
import BloomFoundation
import BloomModel
import CoreHealth
import CoreNetwork
import DataContainer
import SwiftData

/// Routes all messages received from the Apple Watch to appropriate handlers
@MainActor
final class WatchMessageRouter {
  static let shared = WatchMessageRouter()

  private init() {
    setupMessageHandler()
  }

  private func setupMessageHandler() {
    Task {
      await WatchChannel.shared.setMessageHandler { data in
        await WatchMessageRouter.shared.handleMessage(data)
      }
    }
  }

  private func handleMessage(_ data: Data) async -> Data {
    // Try bowel movement message
    if let message = try? JSONDecoder.watch.decode(WatchBowelMovementMessage.self, from: data),
       message.type == WatchBowelMovementMessage.messageType {
      return await handleBowelMovement(message)
    }

    // Try reminder completion message
    if let message = try? JSONDecoder.watch.decode(WatchReminderCompletionMessage.self, from: data),
       message.type == WatchReminderCompletionMessage.messageType {
      return await handleReminderCompletion(message)
    }

    // Try food log message
    if let message = try? JSONDecoder.watch.decode(WatchFoodLogMessage.self, from: data),
       message.type == WatchFoodLogMessage.messageType {
      return await handleFoodLog(message)
    }

    // Try voice food log message
    if let message = try? JSONDecoder.watch.decode(WatchVoiceFoodLogMessage.self, from: data),
       message.type == WatchVoiceFoodLogMessage.messageType {
      return await handleVoiceFoodLog(message)
    }

    // Try meal log message
    if let message = try? JSONDecoder.watch.decode(WatchMealLogMessage.self, from: data),
       message.type == WatchMealLogMessage.messageType {
      return await handleMealLog(message)
    }

    // Try sync request message
    if let message = try? JSONDecoder.watch.decode(WatchSyncRequestMessage.self, from: data),
       message.type == WatchSyncRequestMessage.messageType {
      return await handleSyncRequest(message)
    }

    // Try food search message
    if let message = try? JSONDecoder.watch.decode(WatchFoodSearchMessage.self, from: data),
       message.type == WatchFoodSearchMessage.messageType {
      return await handleFoodSearch(message)
    }

    // Try heart rate zone settings message
    if let message = try? JSONDecoder.watch.decode(WatchHeartRateZoneSettingsMessage.self, from: data),
       message.type == WatchHeartRateZoneSettingsMessage.messageType {
      return await handleHeartRateZoneSettings(message)
    }

    // Unknown message type
    return Data()
  }

  // MARK: - Bowel Movement Handler

  private func handleBowelMovement(_ message: WatchBowelMovementMessage) async -> Data {
    let entry = message.entry
    let success = await saveBowelMovement(entry)

    let response = WatchBowelMovementResponse(success: success, entryId: entry.id)
    return (try? JSONEncoder.watch.encode(response)) ?? Data()
  }

  private func saveBowelMovement(_ entry: WatchBowelMovementEntry) async -> Bool {
    do {
      let context = ContainerHolder.shared.createContext()

      // Check for duplicate by recordID
      let recordID = entry.id
      let descriptor = FetchDescriptor<BowelMovement>(
        predicate: #Predicate { $0.recordID == recordID }
      )

      let existing = try context.fetch(descriptor)
      if !existing.isEmpty {
        // Already exists, consider it a success
        return true
      }

      // Create and insert the bowel movement
      let duration = BowelMovement.Duration(rawValue: entry.rawDuration) ?? .between5And10Min
      let bowelMovement = BowelMovement(
        date: entry.date,
        bristolStoolType: entry.bristolStoolType,
        duration: duration,
        recordID: entry.id
      )

      context.insert(bowelMovement)
      try context.save()

      // Defer expensive work to AFTER response is sent
      Task.detached { [entryId = entry.id] in
        // Confirm via application context (backup to direct response)
        await WatchConfirmationSyncer.shared.confirmBowelMovement(id: entryId)
        await YouStatsCalculator.shared.refreshBowelMovements()
      }

      return true
    } catch {
      return false
    }
  }

  // MARK: - Reminder Completion Handler

  private func handleReminderCompletion(_ message: WatchReminderCompletionMessage) async -> Data {
    do {
      switch message.action {
      case .complete:
        try await RemindersManager.shared.markReminderCompleted(
          withID: message.reminderID,
          occurrenceID: message.occurrenceID,
          source: .manual
        )
      case .uncomplete:
        try await RemindersManager.shared.markReminderUncompleted(
          withID: message.reminderID,
          occurrenceID: message.occurrenceID
        )
      }

      let response = WatchReminderCompletionResponse(
        success: true,
        reminderID: message.reminderID,
        isNowCompleted: message.action == .complete
      )
      let responseData = (try? JSONEncoder.watch.encode(response)) ?? Data()

      // Defer sync to AFTER response is sent
      Task.detached {
        await WatchTodaySyncer.shared.syncToWatch()
      }

      return responseData
    } catch {
      let response = WatchReminderCompletionResponse(
        success: false,
        reminderID: message.reminderID,
        isNowCompleted: false
      )
      return (try? JSONEncoder.watch.encode(response)) ?? Data()
    }
  }

  // MARK: - Food Log Handler

  private func handleFoodLog(_ message: WatchFoodLogMessage) async -> Data {
    do {
      let meal = FoodItemLog.Meal(rawValue: message.meal) ?? .snack
      let logID = try await logFoodItem(
        entryID: message.entryID,
        foodItemID: message.foodItemID,
        meal: meal,
        numberOfServings: message.numberOfServings,
        date: message.date
      )

      let response = WatchFoodLogResponse(success: true, logID: logID)
      let responseData = (try? JSONEncoder.watch.encode(response)) ?? Data()

      // Defer sync to AFTER response is sent
      Task.detached { [entryID = message.entryID] in
        // Confirm via application context (backup to direct response)
        await WatchConfirmationSyncer.shared.confirmFoodLog(id: entryID)
        await WatchFoodSyncer.shared.syncToWatch()
      }

      return responseData
    } catch {
      let response = WatchFoodLogResponse(success: false, errorMessage: error.localizedDescription)
      return (try? JSONEncoder.watch.encode(response)) ?? Data()
    }
  }

  private func logFoodItem(
    entryID: String,
    foodItemID: String,
    meal: FoodItemLog.Meal,
    numberOfServings: Double,
    date: Date
  ) async throws -> String {
    let context = ContainerHolder.shared.createContext()

    // Check for existing log with same entryID (idempotency)
    let existingLogDescriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate { $0.id == entryID }
    )
    if let existingLog = try context.fetch(existingLogDescriptor).first {
      return existingLog.id
    }

    // Try to find existing food item record
    let descriptor = FetchDescriptor<FoodItemRecord>(
      predicate: #Predicate { $0.id == foodItemID }
    )

    let foodItem: FoodItemRecord
    if let existing = try context.fetch(descriptor).first {
      foodItem = existing
    } else {
      // Not found locally - fetch from API and create record
      // This handles watch search results which use API IDs
      let apiFoodItem = try await NetworkRequester.shared.getFoodItem(id: foodItemID)
      foodItem = FoodItemRecord(foodItem: apiFoodItem)
      context.insert(foodItem)
    }

    // Create serving
    let serving = FoodItemServing(numberOfServings: numberOfServings, foodItem: foodItem)

    // Create log using the watch entryID as the log ID for idempotency
    let log = FoodItemLog(
      id: entryID,
      name: foodItem.name,
      date: date,
      meal: meal,
      numberOfServings: numberOfServings,
      imageData: nil,
      foodItemServings: [serving]
    )
    context.insert(log)

    try context.save()

    // Update HealthKit
    try await HealthStoreModifier.shared.updateNutrition(for: date)

    return log.id
  }

  // MARK: - Voice Food Log Handler

  private func handleVoiceFoodLog(_ message: WatchVoiceFoodLogMessage) async -> Data {
    do {
      let meal = FoodItemLog.Meal(rawValue: message.meal) ?? .snack
      let processingIdentifier = try await processVoiceFoodLog(
        transcribedText: message.transcribedText,
        meal: meal,
        date: message.date
      )

      let response = WatchVoiceFoodLogResponse(success: true, processingIdentifier: processingIdentifier)
      return (try? JSONEncoder.watch.encode(response)) ?? Data()
    } catch {
      let response = WatchVoiceFoodLogResponse(success: false, errorMessage: error.localizedDescription)
      return (try? JSONEncoder.watch.encode(response)) ?? Data()
    }
  }

  private func processVoiceFoodLog(
    transcribedText: String,
    meal: FoodItemLog.Meal,
    date: Date
  ) async throws -> String {
    let processingIdentifier = AIFoodProcessingIdentifier()

    // Upload to backend for AI processing
    _ = try await NetworkRequester.shared.uploadMagicScan(
      imageData: nil,
      contextText: transcribedText,
      processingIdentifier: processingIdentifier,
      country: LocationManagerViewModel.shared.country ?? "usa"
    )

    // Log with pending state using NutritionTrackingViewModel
    let context = ContainerHolder.shared.createContext()
    NutritionTrackingViewModel.shared.logTextOnlyMagicScan(
      modelContext: context,
      processingIdentifier: processingIdentifier,
      contextText: transcribedText,
      date: date,
      meal: meal
    )

    return processingIdentifier.value
  }

  // MARK: - Meal Log Handler

  private func handleMealLog(_ message: WatchMealLogMessage) async -> Data {
    do {
      let meal = FoodItemLog.Meal(rawValue: message.meal) ?? .snack
      let logID = try await logMealRecord(
        mealRecordID: message.mealRecordID,
        meal: meal,
        date: message.date
      )

      let response = WatchFoodLogResponse(success: true, logID: logID)
      let responseData = (try? JSONEncoder.watch.encode(response)) ?? Data()

      // Defer sync to AFTER response is sent
      Task.detached {
        await WatchFoodSyncer.shared.syncToWatch()
      }

      return responseData
    } catch {
      let response = WatchFoodLogResponse(success: false, errorMessage: error.localizedDescription)
      return (try? JSONEncoder.watch.encode(response)) ?? Data()
    }
  }

  private func logMealRecord(
    mealRecordID: String,
    meal: FoodItemLog.Meal,
    date: Date
  ) async throws -> String {
    let context = ContainerHolder.shared.createContext()

    // Find the meal record
    let descriptor = FetchDescriptor<MealRecord>(
      predicate: #Predicate { $0.id == mealRecordID }
    )
    guard let mealRecord = try context.fetch(descriptor).first else {
      throw NSError(domain: "WatchMealLog", code: 404, userInfo: [
        NSLocalizedDescriptionKey: "Meal record not found"
      ])
    }

    // Use NutritionTrackingViewModel to log the meal
    try await NutritionTrackingViewModel.shared.log(
      modelContext: context,
      mealRecord: mealRecord,
      numberOfServings: 1,
      date: date,
      meal: meal
    )

    return mealRecord.id
  }

  // MARK: - Sync Request Handler

  private func handleSyncRequest(_ message: WatchSyncRequestMessage) async -> Data {
    // Trigger all syncers in parallel
    async let unitSync: () = HealthUnitPreferences.shared.syncToWatch()
    async let heartRateSync: HeartRateZones? = HealthGoalProvider.shared.heartRateZones()
    async let bioAgeSync: () = BiologicalAgeCalculator.shared.syncBiologicalAgeToWatch()
    async let todaySync: () = WatchTodaySyncer.shared.syncToWatch()
    async let foodSync: () = WatchFoodSyncer.shared.syncToWatch()
    async let subscriptionSync: () = EntitlementController.shared.syncToWatch()
    async let goalSync: () = WatchGoalSyncer.shared.syncToWatch()
    async let hrzSettingsSync: () = WatchHeartRateZoneSettingsSyncer.shared.syncToWatch()
    async let bioSexSync: () = HealthManager.shared.syncBiologicalSexToWatch()

    // Await all syncs
    _ = await (unitSync, heartRateSync, bioAgeSync, todaySync, foodSync, subscriptionSync, goalSync, hrzSettingsSync, bioSexSync)

    let response = WatchSyncRequestResponse(success: true)
    return (try? JSONEncoder.watch.encode(response)) ?? Data()
  }

  // MARK: - Food Search Handler

  private func handleFoodSearch(_ message: WatchFoodSearchMessage) async -> Data {
    do {
      let sections = try await NetworkRequester.shared.foodSearch(
        name: message.query,
        brand: nil,
        preferredCountry: message.country
      )

      // Convert to WatchFoodItem format (limit results for watch)
      let watchFoods = sections.flatMap { $0.foods }
        .prefix(20)
        .map { food in
          WatchFoodItem(
            id: food.id.value,
            name: food.name,
            brandName: food.brandName,
            calories: food.calories?.value ?? 0,
            protein: food.protein?.value ?? 0,
            carbs: food.carbohydrates?.value ?? 0,
            fat: food.fat?.value ?? 0,
            servingName: food.servingName ?? "serving",
            isVerified: food.isVerified
          )
        }

      let response = WatchFoodSearchResponse(success: true, foods: Array(watchFoods))
      return (try? JSONEncoder.watch.encode(response)) ?? Data()
    } catch {
      let response = WatchFoodSearchResponse(success: false, errorMessage: error.localizedDescription)
      return (try? JSONEncoder.watch.encode(response)) ?? Data()
    }
  }

  // MARK: - Heart Rate Zone Settings Handler

  private func handleHeartRateZoneSettings(_ message: WatchHeartRateZoneSettingsMessage) async -> Data {
    let success = await WatchHeartRateZoneSettingsSyncer.shared.handleSettingsFromWatch(message)
    let response = WatchHeartRateZoneSettingsResponse(success: success)
    return (try? JSONEncoder.watch.encode(response)) ?? Data()
  }
}
