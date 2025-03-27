//
//  ModelContext+MealRecords.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftData

public extension ModelContext {

  func fetchAllMealRecords() throws -> [MealRecord] {
    let descriptor = FetchDescriptor<MealRecord>()
    return try fetch(descriptor)
  }
}
