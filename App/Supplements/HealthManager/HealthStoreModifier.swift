//
//  HealthStoreModifier.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
import DataContainer
@preconcurrency import HealthKit

// MARK: - HealthType

/// Making the logged health types opt-in.
/// We can leverage allCases to make logging more generic.
enum HealthType: CaseIterable {
  case calories
  case protein
  case carbohydrates
  case fat

  var identifier: HKQuantityTypeIdentifier {
    switch self {
    case .calories: .dietaryEnergyConsumed
    case .protein: .dietaryProtein
    case .carbohydrates: .dietaryCarbohydrates
    case .fat: .dietaryFatTotal
    }
  }

  var unit: HKUnit {
    switch self {
    case .calories: .kilocalorie()
    case .protein: .gram()
    case .carbohydrates: .gram()
    case .fat: .gram()
    }
  }

  func getServingSize(_ foodItem: FoodItemDTO) -> Double {
    let servingValue = foodItem.servingValue ?? 0
    let value = switch self {
    case .calories: foodItem.calories
    case .protein: foodItem.protein
    case .carbohydrates: foodItem.carbohydrates
    case .fat: foodItem.fat
    }

    return servingValue * value
  }
}

// MARK: - HealthStoreModifier

final actor HealthStoreModifier {
    static let shared = HealthStoreModifier()

    private let healthStore = HKHealthStore()
    private let foodItemLogModel = FoodItemLogModelActor(modelContainer: ContainerHolder.shared.container)

    private init() { }
}

// MARK: Generic Writes

extension HealthStoreModifier {

    func write(sample: HKObject) async throws {
        try await healthStore.save(sample)
    }

    func write(samples: [HKObject]) async throws {
        try await healthStore.save(samples)
    }
}

// MARK: Nutrition

extension HealthStoreModifier {

    func updateNutrition(for date: Date) async throws {
        // TODO: Fetch FoodItemLogs from SwiftData
        // Fetch data logged to HealthKit by Bloom (not sure if we can filter by who logged the data)
        // Recalculate the nutrition amounts for each time block (breakfast, lunch, dinner, snack)
        // Write the new data to HealthKit, if necessary

      let foodLogs = try await foodItemLogModel.fetchLogs(for: date)

      // Fetch and delete all entries for the day.
      try await clearExistingEntries(for: date)
      // Write food logs to HealthKit.
      try await recordFoodLogs(foodLogs)
    }
}

private extension HealthStoreModifier {
  func clearExistingEntries(for date: Date) async throws {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

    let dayPredicate = HKQuery.predicateForSamples(
      withStart: startOfDay,
      end: endOfDay,
      options: .strictEndDate
    )

    guard let appBundleIdentifier = Bundle.main.bundleIdentifier else {
      throw NSError(description: "Unable to fetch bundle ID")
    }

    let metadataPredicate = HKQuery.predicateForObjects(withMetadataKey: "AppIdentifier", allowedValues: [appBundleIdentifier])
    // Find all entries for the day that were logged by Bloom.
    let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dayPredicate, metadataPredicate])

    // We need to find and delete for each quantity type. ex calories, protein, carbs, fat.
    for sampleType in HealthType.allCases {
      do {
        let type = HKQuantityType.quantityType(forIdentifier: sampleType.identifier)!
        let samples = try await fetchSamples(for: type, predicate: combinedPredicate)
        guard samples.isNotEmpty else { return }
        // Cast to the correct type for delete. HKSamples are also HKObjects.
        let objects = samples as [HKObject]
        try await healthStore.delete(objects)
      } catch {
        print("Error fetching or deleting samples for \(sampleType.identifier): \(error.localizedDescription)")
      }
    }
  }

  func fetchSamples(for sampleType: HKQuantityType, predicate: NSPredicate) async throws -> [HKSample] {
    try await withCheckedThrowingContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: sampleType,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: nil
      ) { _, samples, error in
        if let error = error {
          continuation.resume(throwing: error)
        } else if let samples = samples {
          // Passing HKSample risks a data race because it isn't sendable but there isn't a good way to reconstruct it...
          continuation.resume(returning: samples)
        } else {
          continuation.resume(returning: [])
        }
      }

      healthStore.execute(query)
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
    try await write(samples: samples)
  }

  func createFoodSamples(_ foodItemLog: FoodItemLogDTO) -> [HKQuantitySample] {
    HealthType.allCases.compactMap { type in
      createFoodSample(
        foodItemLog,
        type: type
      )
    }
  }

  func createFoodSample(
    _ foodItemLog: FoodItemLogDTO,
    type: HealthType
  ) -> HKQuantitySample? {
    guard let foodItem = foodItemLog.foodItem else { return nil }

    let servingValue = type.getServingSize(foodItem)
    let quantity = HKQuantity(
      unit: type.unit,
      doubleValue: servingValue * foodItemLog.numberOfServings
    )

    let metaData: [String: Any] = [
      HKMetadataKeyFoodType: foodItem.name,
      "brandName": foodItem.brandName,
      "servingName": foodItem.servingName ?? "",
      // TODO: any other metadata here. Remember an app identifier.
    ]

    return HKQuantitySample(
      type: .quantityType(forIdentifier: type.identifier)!,
      quantity: quantity,
      start: foodItemLog.date,
      end: foodItemLog.date,
      metadata: metaData
    )
  }
}
