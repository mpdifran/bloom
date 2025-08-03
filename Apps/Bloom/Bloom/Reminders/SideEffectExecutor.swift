//
//  SideEffectExecutor.swift
//  Bloom
//
//  Created by Assistant on 2025-08-03.
//

import Foundation
import SwiftData
import HealthKit
import DataContainer
import BloomModel
import TelemetryDeck
import CoreHealth

/// Service responsible for executing side effects when reminders are completed
actor SideEffectExecutor {
  static let shared = SideEffectExecutor()

  private let foodItemModelActor = FoodItemModelActor.standard()
  
  private init() {}
  
  /// Executes all side effects for a completed reminder
  func executeSideEffects(for reminder: ReminderDTO) async -> [SideEffectExecutionResult] {
    guard !reminder.sideEffects.isEmpty else { return [] }
    
    var results: [SideEffectExecutionResult] = []
    
    for sideEffect in reminder.sideEffects {
      guard let sideEffectType = sideEffect.type else {
        TelemetryDeck.errorOccurred(
          id: "SideEffectExecutor.invalidSideEffectType",
          category: .thrownException,
          message: "Invalid side effect type raw value: \(sideEffect.typeRawValue)"
        )
        continue
      }
      
      do {
        let recordID: String?
        switch sideEffectType {
        case .logFood:
          recordID = try await executeLogFood(sideEffect)
        case .logWater:
          recordID = try await executeLogWater(sideEffect)
        @unknown default:
          TelemetryDeck.errorOccurred(
            id: "SideEffectExecutor.unknownSideEffectType",
            category: .thrownException,
            message: "Unknown side effect type: \(sideEffectType)"
          )
          recordID = nil
        }
        
        results.append(SideEffectExecutionResult(
          sideEffectID: sideEffect.id,
          type: sideEffectType,
          createdRecordID: recordID,
          success: true
        ))
        
      } catch {
        TelemetryDeck.errorOccurred(
          id: "SideEffectExecutor.executionFailed",
          category: .thrownException,
          message: "Failed to execute side effect \(sideEffect.id): \(error.localizedDescription)"
        )
        
        results.append(SideEffectExecutionResult(
          sideEffectID: sideEffect.id,
          type: sideEffectType,
          createdRecordID: nil,
          success: false
        ))
      }
    }
    
    return results
  }
  
  /// Undoes side effects for a completed reminder
  func undoSideEffects(results: [SideEffectExecutionResult]) async {
    for result in results where result.success && result.createdRecordID != nil {
      do {
        switch result.type {
        case .logFood:
          try await undoLogFood(recordID: result.createdRecordID!)
        case .logWater:
          try await undoLogWater(recordID: result.createdRecordID!)
        @unknown default:
          TelemetryDeck.errorOccurred(
            id: "SideEffectExecutor.unknownUndoType",
            category: .thrownException,
            message: "Unknown side effect type for undo: \(result.type)"
          )
        }
      } catch {
        TelemetryDeck.errorOccurred(
          id: "SideEffectExecutor.undoFailed",
          category: .thrownException,
          message: "Failed to undo side effect \(result.sideEffectID): \(error.localizedDescription)"
        )
      }
    }
  }
  
  /// Undoes a food logging side effect
  private func undoLogFood(recordID: String) async throws {
    let modelContext = ModelContext(ContainerHolder.shared.container)
    
    // Find and delete the food item log
    if let foodItemLog = try modelContext.fetchFoodItemLog(id: recordID) {
      try await NutritionTrackingViewModel.shared.delete(
        modelContext: modelContext,
        foodItemLogs: [foodItemLog]
      )
      
      TelemetryDeck.signal("Reminder Side Effect Undone", parameters: ["type": "log_food"])
    }
  }
  
  /// Undoes a water logging side effect
  private func undoLogWater(recordID: String) async throws {
    guard let uuid = UUID(uuidString: recordID) else { return }
    
    // Delete the sample from HealthKit
    try await HealthStoreModifier.shared.deleteSample(
      uuid: uuid,
      ofType: HKQuantityType(.dietaryWater)
    )
    
    TelemetryDeck.signal("Reminder Side Effect Undone", parameters: ["type": "log_water"])
  }
}

// MARK: - Private Methods

private extension SideEffectExecutor {

  /// Executes a food logging side effect
  func executeLogFood(_ sideEffect: ReminderSideEffectDTO) async throws -> String {
    guard let config = sideEffect.decodeConfiguration(as: LogFoodSideEffectConfig.self) else {
      throw SideEffectError.invalidConfiguration
    }

    // Fetch the food item from the database
    guard let foodItemDTO = try await foodItemModelActor.fetchFoodItem(for: config.foodItemID) else {
      throw SideEffectError.foodItemNotFound(config.foodItemID)
    }

    // Convert DTO to BloomModel.FoodItem for the nutrition view model
    // Use the existing conversion method
    let foodItem = foodItemDTO.asNetworkFoodItem()

    // Create a new model context for the food logging operation
    let modelContext = ModelContext(ContainerHolder.shared.container)

    // Use the nutrition view model to log the food
    let logID = try await NutritionTrackingViewModel.shared.log(
      modelContext: modelContext,
      foodItem: foodItem,
      date: Date.now,
      meal: config.meal,
      numberOfServings: config.servingSize
    )

    SoundPlayer.playLogHealthData()

    TelemetryDeck.signal("Reminder Side Effect Executed", parameters: ["type": "log_food"])

    return logID
  }

  /// Executes a water logging side effect
  func executeLogWater(_ sideEffect: ReminderSideEffectDTO) async throws -> String {
    guard let config = sideEffect.decodeConfiguration(as: LogWaterSideEffectConfig.self) else {
      throw SideEffectError.invalidConfiguration
    }

    // Create HKQuantitySample for water
    let unit = HKUnit(from: config.unitString)
    let quantity = HKQuantity(unit: unit, doubleValue: config.amount)

    let sample = HKQuantitySample(
      type: HKQuantityType(.dietaryWater),
      quantity: quantity,
      start: Date.now,
      end: Date.now,
      metadata: [
        HKMetadataKeyWasUserEntered: true
      ]
    )

    // Write to HealthKit
    try await HealthStoreModifier.shared.write(sample)

    SoundPlayer.playLogHealthData()

    TelemetryDeck.signal("Reminder Side Effect Executed", parameters: ["type": "log_water"])

    return sample.uuid.uuidString
  }
}

// MARK: - Supporting Types

enum SideEffectError: LocalizedError {
  case invalidConfiguration
  case foodItemNotFound(String)
  
  var errorDescription: String? {
    switch self {
    case .invalidConfiguration:
      return "Invalid side effect configuration"
    case .foodItemNotFound(let id):
      return "Food item not found: \(id)"
    }
  }
}

