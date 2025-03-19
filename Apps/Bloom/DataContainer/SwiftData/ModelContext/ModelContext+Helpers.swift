//
//  ModelContext+Helpers.swift
//  DataContainer
//
//  Created by Mark DiFranco on 2024-09-23.
//

import Foundation
import SwiftData
import BloomFoundation
internal import AppFoundations

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

  func fetchFirstFoodItem(for id: String) throws -> FoodItemRecord? {
    let descriptor = FetchDescriptor<FoodItemRecord>(
      predicate: #Predicate<FoodItemRecord> { model in
        model.id == id
      }
    )
    return try fetch(descriptor).first
  }

  func fetchAllFoodItems(for id: String) throws -> [FoodItemRecord] {
    let descriptor = FetchDescriptor<FoodItemRecord>(
      predicate: #Predicate<FoodItemRecord> { model in
        model.id == id
      }
    )
    return try fetch(descriptor)
  }

  /// Merges food items that have the same ID as the first food item, maintaining relationships. Properties are not merged.
  func merge(_ foodItems: [FoodItemRecord]) throws -> FoodItemRecord? {
    guard let firstFoodItem = foodItems.first else { return nil }

    let id = firstFoodItem.id
    let remainingFoodItems = foodItems.dropFirst().filter({ $0.id == id })

    for foodItem in remainingFoodItems {
      for serving in foodItem.servings ?? [] {
        serving.foodItem = firstFoodItem
      }
      for mealItem in foodItem.mealItems ?? [] {
        mealItem.foodItem = firstFoodItem
      }
      delete(foodItem)
    }

    try save()

    return firstFoodItem
  }

  func fetchOldestFoodItemLog() throws -> FoodItemLog? {
    var descriptor = FetchDescriptor<FoodItemLog>(
      sortBy: [SortDescriptor(\FoodItemLog.date, order: .forward)]
    )
    descriptor.fetchLimit = 1
    return try fetch(descriptor).first
  }
}
