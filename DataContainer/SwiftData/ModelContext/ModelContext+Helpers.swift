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
}

public extension ModelContext {

    func fetchBowelMovements(dateRange: DateRange) throws -> [BowelMovement] {
        let start = dateRange.start
        let end = dateRange.end
        let descriptor = FetchDescriptor<BowelMovement>(
            predicate: #Predicate<BowelMovement> { model in
                model.date >= start && model.date <= end
            },
            sortBy: [SortDescriptor(\BowelMovement.date)]
        )
        return try fetch(descriptor)
    }

    func fetchActiveHabits() throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { model in
                model.endDate == nil
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
