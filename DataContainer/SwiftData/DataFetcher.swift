//
//  DataFetcher.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import Foundation
import SwiftData
import BloomFoundation

public final class DataFetcher {
    public static let shared = DataFetcher()

    private let context: ModelContext

    private init() {
        let context = ModelContext(ContainerHolder.shared.container)
        self.context = context
    }
}

public extension DataFetcher {

//    func fetch<Model>(
//        _ modelType: Model.Type,
//        dateRange: DateRange
//    ) throws -> [Model] where Model: PersistentModel, Model: IdentifiableByDate {
//        let start = dateRange.start
//        let end = dateRange.end
//        let descriptor = FetchDescriptor<Model>(
//            predicate: #Predicate<Model> { model in
//                model.date >= start && model.date <= end
//            },
//            sortBy: [SortDescriptor(\.date)]
//        )
//        return try context.fetch(descriptor)
//    }

    func fetchBowelMovements(dateRange: DateRange) throws -> [BowelMovement] {
        let start = dateRange.start
        let end = dateRange.end
        let descriptor = FetchDescriptor<BowelMovement>(
            predicate: #Predicate<BowelMovement> { model in
                model.date >= start && model.date <= end
            },
            sortBy: [SortDescriptor(\BowelMovement.date)]
        )
        return try context.fetch(descriptor)
    }

    func fetchActiveHabits(source: Habit.Source) throws -> [Habit] {
        let rawSource = source.rawValue
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { model in
                model.endDate == nil && model.source.rawValue == rawSource
            },
            sortBy: [SortDescriptor(\Habit.startDate)]
        )
        return try context.fetch(descriptor)
    }

    func fetchHabits(for targetMetric: TargetMetric, source: Habit.Source) throws -> [Habit] {
        let rawSource = source.rawValue
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { model in
                model.targetMetric == targetMetric && model.source.rawValue == rawSource
            },
            sortBy: [SortDescriptor(\Habit.startDate)]
        )
        return try context.fetch(descriptor)
    }
}
