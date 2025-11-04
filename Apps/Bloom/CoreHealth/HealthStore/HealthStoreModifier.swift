//
//  HealthStoreModifier.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
import DataContainer
internal import TelemetryDeck
@preconcurrency import HealthKit

// MARK: - HealthStoreModifier

enum HealthStoreError: Error {
  case invalidUUID
}

public final actor HealthStoreModifier {
  public static let shared = HealthStoreModifier()

  private let healthStore = HKHealthStore()
  private let foodItemLogModel = FoodItemLogModelActor(modelContainer: ContainerHolder.shared.container)

  // Queue of pending updates to prevent race conditions
  private var updateQueue: [Date: [CheckedContinuation<Void, Error>]] = [:]

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

  func deleteSample(uuid: UUID, ofType sampleType: HKSampleType) async throws {
    let predicate = HKQuery.predicateForObjects(with: [uuid])
    try await healthStore.deleteObjects(of: sampleType, predicate: predicate)
  }
}

// MARK: Nutrition

public extension HealthStoreModifier {

  func updateNutrition(for date: Date) async throws {
    // Normalize date to start of day to ensure consistency
    let normalizedDate = Calendar.current.startOfDay(for: date)

    // Add ourselves to the queue and wait for our turn
    let wasEmpty = updateQueue[normalizedDate]?.isEmpty ?? true

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      updateQueue[normalizedDate, default: []].append(continuation)

      // If queue was empty before we added ourselves, we're first - start processing
      if wasEmpty {
        Task {
          await processUpdateQueue(for: normalizedDate)
        }
      }
    }
  }

  private func processUpdateQueue(for date: Date) async {
    // Process queue entries one at a time until empty
    while let continuation = updateQueue[date]?.first {
      do {
        // Fetch latest data from database
        let foodLogs = try await foodItemLogModel.fetchLogs(for: date)

        // Perform bulk deletion and insertion
        try await performBulkNutritionUpdate(for: date, with: foodLogs)

        // Success - remove from queue and resume the waiting call
        updateQueue[date]?.removeFirst()
        continuation.resume()
      } catch {
        // Error - remove from queue and propagate error
        updateQueue[date]?.removeFirst()
        continuation.resume(throwing: error)
      }
    }

    // Queue is empty, clean up
    updateQueue[date] = nil
  }
}

// MARK: Blood Pressure

public extension HealthStoreModifier {

  @discardableResult
  func log(systolic: Double, diastolic: Double, date: Date = .now) async throws -> String {
    let metadata = [
      HKMetadataKeyWasUserEntered: true
    ]
    
    let systolicQuantity = HKQuantity(unit: .millimeterOfMercury(), doubleValue: systolic)
    let diastolicQuantity = HKQuantity(unit: .millimeterOfMercury(), doubleValue: diastolic)
    
    let systolicSample = HKQuantitySample(
      type: HKQuantityType(.bloodPressureSystolic),
      quantity: systolicQuantity,
      start: date,
      end: date,
      metadata: metadata
    )
    
    let diastolicSample = HKQuantitySample(
      type: HKQuantityType(.bloodPressureDiastolic),
      quantity: diastolicQuantity,
      start: date,
      end: date,
      metadata: metadata
    )
    
    // Write individual samples (correlations cannot be written by third-party apps)
    try await write([systolicSample, diastolicSample])
    
    TelemetryDeck.signal("Log Blood Pressure")
    
    // Return combined UUID string for storage
    return "\(systolicSample.uuid.uuidString)|\(diastolicSample.uuid.uuidString)"
  }
  
  func deleteBloodPressure(combinedUUID: String) async throws {
    // Split the pipe-separated UUIDs
    let uuidStrings = combinedUUID.split(separator: "|").map(String.init)
    guard uuidStrings.count == 2,
          let systolicUUID = UUID(uuidString: uuidStrings[0]),
          let diastolicUUID = UUID(uuidString: uuidStrings[1]) else {
      throw HealthStoreError.invalidUUID
    }
    
    // Delete both samples
    try await deleteSample(uuid: systolicUUID, ofType: HKQuantityType(.bloodPressureSystolic))
    try await deleteSample(uuid: diastolicUUID, ofType: HKQuantityType(.bloodPressureDiastolic))
  }
}

// MARK: Cycle Tracking

public extension HealthStoreModifier {

  @discardableResult
  func log(flowType: HKCategoryValueVaginalBleeding, date: Date) async throws -> UUID? {
    var isNewCycle = flowType.indicatesBeginningOfCycle
    if await isCurrentPeriod() {
      isNewCycle = false
    }

    let metadata: [String: Any] = [
      HKMetadataKeyMenstrualCycleStart: isNewCycle
    ]

    let normalizedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date

    let existingSamples = try await HealthStoreFetcher.shared.fetchSamples(
      for: HKCategoryType(.menstrualFlow),
      dateRange: .duringDay(date)
    )
    if existingSamples.isNotEmpty {
      try await HealthStoreModifier.shared.delete(existingSamples)
    }

    var uuid: UUID?
    if flowType != .none {
      let sample = HKCategorySample(
        type: HKCategoryType(.menstrualFlow),
        value: flowType.rawValue,
        start: normalizedDate,
        end: normalizedDate,
        metadata: metadata
      )

      try await HealthStoreModifier.shared.write(sample)
      TelemetryDeck.signal("Log Period")
      uuid = sample.uuid
    }

    await VitalsCalculator.shared.forceFectchMenstrualSummary()

    return uuid
  }
}

private extension HealthStoreModifier {

  func isCurrentPeriod() async -> Bool {
    await VitalsCalculator.shared.forceFectchMenstrualSummary()

    guard let mostRecentMenstrualCycle = await VitalsCalculator.shared.menstrualSummary?.mostRecentCycle else { return false }

    let referenceDate = mostRecentMenstrualCycle.endDate ?? mostRecentMenstrualCycle.startDate

    let daysSinceLastCycle = Calendar.current.dateComponents(
      [.day],
      from: referenceDate,
      to: .now
    ).day ?? 0

    return daysSinceLastCycle < 7
  }

  /// Performs an optimized bulk update of nutrition data
  /// This method batches all operations to minimize HealthKit transactions
  func performBulkNutritionUpdate(for date: Date, with foodLogs: [FoodItemLogDTO]) async throws {
    // Step 1: Collect all samples to delete in a single batch
    var samplesToDelete: [HKSample] = []
    
    // Fetch all existing samples for the day in parallel
    try await withThrowingTaskGroup(of: [HKSample].self) { group in
      for nutrientType in FoodItemNutrient.allCases {
        group.addTask {
          let type = HKQuantityType(nutrientType.identifier)
          let samples = try await HealthStoreFetcher.shared.fetchSamples(
            for: type,
            dateRange: .duringDay(date),
            writtenByApp: true
          )
          return samples
        }
      }

      for try await samples in group {
        samplesToDelete.append(contentsOf: samples)
      }
    }
    
    // Step 2: Create all new samples
    let newSamples = foodLogs.flatMap { log in
      createFoodSamples(log)
    }
    
    // Step 3: Perform bulk operations
    // Delete all old samples in one operation
    if samplesToDelete.isNotEmpty {
      try await healthStore.delete(samplesToDelete)
    }
    
    // Write all new samples in one operation
    if newSamples.isNotEmpty {
      try await healthStore.save(newSamples)
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
