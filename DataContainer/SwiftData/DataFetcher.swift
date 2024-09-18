//
//  DataFetcher.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import Foundation
import SwiftData
import BloomFoundation

public final actor DataFetcher {
    public static let shared = DataFetcher()

    private let context: ModelContext

    private init() {
        let context = ModelContext(ContainerHolder.shared.container)
        context.autosaveEnabled = true
        self.context = context
    }
}

public extension DataFetcher {

    func fetch<Model>(
        _ modelType: Model.Type,
        dateRange: DateRange
    ) throws -> [Model] where Model: PersistentModel, Model: IdentifiableByDate {
        let start = dateRange.start
        let end = dateRange.end
        let descriptor = FetchDescriptor<Model>(
            predicate: #Predicate<Model> { model in
                model.date >= start && model.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }

    func fetchBowelMovements(dateRange: DateRange) throws -> [BowelMovement] {
        let start = dateRange.start
        let end = dateRange.end
        let descriptor = FetchDescriptor<BowelMovement>(
            predicate: #Predicate<BowelMovement> { model in
                model.date >= start && model.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }

    func fetchHabits(dateRange: DateRange) throws -> [Habit] {
        let start = dateRange.start
        let end = dateRange.end
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { model in
                model.date >= start && model.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }
}
