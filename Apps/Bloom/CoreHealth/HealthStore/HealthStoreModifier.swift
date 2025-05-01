//
//  HealthStoreModifier.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
import DataContainer
@preconcurrency import HealthKit

// MARK: - HealthStoreModifier

public final actor HealthStoreModifier {
  public static let shared = HealthStoreModifier()

  private let healthStore = HKHealthStore()
  private let foodItemLogModel = FoodItemLogModelActor(modelContainer: ContainerHolder.shared.container)

  private init() { }
}

// MARK: Generic Writes

public extension HealthStoreModifier {

  func write(_ sample: HKObject) async throws {
    try await healthStore.save(sample)
  }

  func write(_ samples: [HKObject]) async throws {
    try await healthStore.save(samples)
  }

  func delete(_ sample: HKObject) async throws {
    try await healthStore.delete(sample)
  }

  func delete(_ samples: [HKObject]) async throws {
    try await healthStore.delete(samples)
  }
}

// MARK: Nutrition

public extension HealthStoreModifier {

  func updateNutrition(for date: Date) async throws {
    // Fetch logs from local database.
    let foodLogs = try await foodItemLogModel.fetchLogs(for: date)
    // Fetch and delete all entries for the day.
    try await clearExistingEntries(for: date)
    // Write food logs to HealthKit.
    try await recordFoodLogs(foodLogs)
  }
}

private extension HealthStoreModifier {
  func clearExistingEntries(for date: Date) async throws {
    // We need to find and delete for each quantity type. ex calories, protein, carbs, fat.
    for sampleType in FoodItemNutrient.allCases {
      do {
        let type = HKQuantityType(sampleType.identifier)
        let samples = await HealthStoreFetcher.shared.fetchSamples(
          for: type,
          dateRange: .duringDay(date),
          writtenByApp: true
        )
        if samples.isNotEmpty {
          try await healthStore.delete(samples)
        }
      } catch {
        print("Error deleting samples for \(sampleType.identifier): \(error.localizedDescription)")
      }
    }
  }

  func recordFoodLogs(_ foodItemLogs: [FoodItemLogDTO]) async throws {
    // Each log will make entries for each log, for the samples: calories, protein, carbs, and fat.
    // These will be batched, and logged once.
    let samples = foodItemLogs.flatMap { log in
      createFoodSamples(log)
    }

    guard samples.isNotEmpty else { return }
    // Write to HealthKit
    try await write(samples)
  }

  func createFoodSamples(_ foodItemLog: FoodItemLogDTO) -> [HKQuantitySample] {
    FoodItemNutrient.allCases.flatMap { type in
      createFoodSample(
        foodItemLog,
        type: type
      )
    }
  }

  func createFoodSample(
    _ foodItemLog: FoodItemLogDTO,
    type: FoodItemNutrient
  ) -> [HKQuantitySample] {
    foodItemLog.foodItemServings.compactMap { (foodItemServing) in
      guard
        let foodItem = foodItemServing.foodItem,
        let amount = type.value(for: foodItem),
        amount > 0
      else { return nil }

      let totalAmount = amount * foodItemServing.numberOfServings * foodItemLog.numberOfServings

      let quantity = HKQuantity(
        unit: type.unit,
        doubleValue: totalAmount
      )

      let metaData = HealthMetadata.create(
        [
          .food(foodItem.displayFullName),
          .meal(foodItemLog.meal.name)
        ]
      )

      return HKQuantitySample(
        type: .quantityType(forIdentifier: type.identifier)!,
        quantity: quantity,
        start: foodItemLog.date,
        end: foodItemLog.date,
        metadata: metaData
      )
    }
  }
}
