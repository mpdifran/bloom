//
//  ModelContext+Habits.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftData

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
