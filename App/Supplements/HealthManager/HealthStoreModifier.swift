//
//  HealthStoreModifier.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
@preconcurrency import HealthKit

final actor HealthStoreModifier {
    static let shared = HealthStoreModifier()

    private let healthStore = HKHealthStore()

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
    }
}
