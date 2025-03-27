//
//  MealRecordModelActor.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import BloomFoundation
import Foundation
import SwiftData

@ModelActor
public final actor MealRecordModelActor: SharedModelActor {

  private var context: ModelContext { modelExecutor.modelContext }
}

public extension MealRecordModelActor {

  func fetchAllMealRecords() throws -> [MealRecordDTO] {
    let descriptor = FetchDescriptor<MealRecord>()
    return try context.fetch(descriptor).map { $0.asDTO() }
  }
}
