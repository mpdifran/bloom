//
//  HealthStoreModifier.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
import DataContainer
@preconcurrency import HealthKit

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

      try await clearExistingEntries(for: date)
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

    // Get the bundle identifier of your app
    guard let appBundleIdentifier = Bundle.main.bundleIdentifier else {
      throw NSError(domain: "YourApp", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve bundle identifier."])
    }

    let metadataPredicate = HKQuery.predicateForObjects(withMetadataKey: "AppIdentifier", allowedValues: [appBundleIdentifier])
    let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dayPredicate, metadataPredicate])

    let sampleTypes: [HKQuantityType] = [
      HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
      HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
      HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
      HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
    ]

    for sampleType in sampleTypes {
      do {
        let samples = try await fetchSamples(for: sampleType, predicate: combinedPredicate)
        guard samples.isNotEmpty else { return }
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
          continuation.resume(returning: samples)
        } else {
          continuation.resume(returning: [])
        }
      }

      healthStore.execute(query)
    }
  }
}
