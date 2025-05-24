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

  func deleteSample(uuid: UUID, ofType sampleType: HKSampleType) async throws {
    let predicate = HKQuery.predicateForObjects(with: [uuid])
    try await healthStore.deleteObjects(of: sampleType, predicate: predicate)
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

// MARK: Cycle Tracking

public extension HealthStoreModifier {

  func log(flowType: HKCategoryValueMenstrualFlow, date: Date) async throws {
    var isNewCycle = flowType.indicatesBeginningOfCycle
    if await isCurrentPeriod() {
      isNewCycle = false
    }

    let metadata: [String: Any] = [
      HKMetadataKeyMenstrualCycleStart: isNewCycle
    ]

    let normalizedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date

    let existingSamples = await HealthStoreFetcher.shared.fetchSamples(
      for: HKCategoryType(.menstrualFlow),
      dateRange: .duringDay(date)
    )
    if existingSamples.isNotEmpty {
      try await HealthStoreModifier.shared.delete(existingSamples)
    }

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
    }

    await VitalsCalculator.shared.forceFectchMenstrualSummary()
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
