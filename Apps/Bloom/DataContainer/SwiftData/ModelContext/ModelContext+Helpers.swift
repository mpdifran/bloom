//
//  ModelContext+Helpers.swift
//  DataContainer
//
//  Created by Mark DiFranco on 2024-09-23.
//

import Foundation
import SwiftData
import BloomFoundation

public extension ModelContext {

  func existingModel<T>(for objectID: PersistentIdentifier) throws -> T? where T: PersistentModel {
    if let registered: T = registeredModel(for: objectID) {
      return registered
    }

    let fetchDescriptor = FetchDescriptor<T>(
      predicate: #Predicate {
        $0.persistentModelID == objectID
      })

    return try fetch(fetchDescriptor).first
  }

  func deleteByID<T>(_ model: T) throws where T: PersistentModel {
    guard let localModel: T = try existingModel(for: model.persistentModelID) else { return }

    delete(localModel)
  }
}

public extension ModelContext {

  func fetchActiveHabits() throws -> [Habit] {
    let descriptor = FetchDescriptor<Habit>(
      predicate: #Predicate<Habit> { model in
        model.endDate == nil
      },
      sortBy: [SortDescriptor(\Habit.startDate)]
    )
    return try fetch(descriptor)
  }

  func fetchActiveHabits(for targetMetric: TargetMetric) throws -> [Habit] {
    let descriptor = FetchDescriptor<Habit>(
      predicate: #Predicate<Habit> { model in
        model.endDate == nil && model.rawTargetMetric == targetMetric.rawValue
      },
      sortBy: [SortDescriptor(\Habit.startDate)]
    )
    return try fetch(descriptor)
  }

  func fetchActiveHabits(isSuggested: Bool) throws -> [Habit] {
    let descriptor = FetchDescriptor<Habit>(
      predicate: #Predicate<Habit> { model in
        model.endDate == nil && model.isSuggested == isSuggested
      },
      sortBy: [SortDescriptor(\Habit.startDate)]
    )
    return try fetch(descriptor)
  }

  func fetchHabits(for targetMetric: TargetMetric) throws -> [Habit] {
    let descriptor = FetchDescriptor<Habit>(
      predicate: #Predicate<Habit> { model in
        model.rawTargetMetric == targetMetric.rawValue
      },
      sortBy: [SortDescriptor(\Habit.startDate)]
    )
    return try fetch(descriptor)
  }

  func fetchHabits(for targetMetric: TargetMetric, isSuggested: Bool) throws -> [Habit] {
    let descriptor = FetchDescriptor<Habit>(
      predicate: #Predicate<Habit> { model in
        model.rawTargetMetric == targetMetric.rawValue && model.isSuggested == isSuggested
      },
      sortBy: [SortDescriptor(\Habit.startDate)]
    )
    return try fetch(descriptor)
  }

  func fetchHabit(id: PersistentIdentifier) throws -> Habit? {
    try existingModel(for: id)
  }
}

public extension ModelContext {

  func fetchFoodItem(for id: String) throws -> FoodItemRecord? {
    let descriptor = FetchDescriptor<FoodItemRecord>(
      predicate: #Predicate<FoodItemRecord> { model in
        model.id == id
      }
    )
    return try fetch(descriptor).first
  }

  func fetchOldestFoodItemLog() throws -> FoodItemLog? {
    var descriptor = FetchDescriptor<FoodItemLog>(
      sortBy: [SortDescriptor(\FoodItemLog.date, order: .forward)]
    )
    descriptor.fetchLimit = 1
    return try fetch(descriptor).first
  }
}
