//
//  HabitModelActor.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation
import SwiftData

public extension HabitModelActor {

    static func standard() -> Self {
        .init(modelContainer: ContainerHolder.shared.container)
    }
}

@ModelActor
public final actor HabitModelActor {

    private var context: ModelContext { modelExecutor.modelContext }
}

public extension HabitModelActor {

    func fetchActiveHabits() throws -> [HabitDTO] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { model in
                model.endDate == nil
            },
            sortBy: [SortDescriptor(\Habit.startDate)]
        )
        return try context.fetch(descriptor).map { $0 .asDTO() }
    }

    func fetchActiveHabits(for targetMetric: TargetMetric) throws -> [HabitDTO] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { model in
                model.endDate == nil && model.rawTargetMetric == targetMetric.rawValue
            },
            sortBy: [SortDescriptor(\Habit.startDate)]
        )
        return try context.fetch(descriptor).map { $0.asDTO() }
    }

    func fetchActiveHabits(isSuggested: Bool) throws -> [HabitDTO] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { model in
                model.endDate == nil && model.isSuggested == isSuggested
            },
            sortBy: [SortDescriptor(\Habit.startDate)]
        )
        return try context.fetch(descriptor).map { $0.asDTO() }
    }

    func fetchHabits(for targetMetric: TargetMetric) throws -> [HabitDTO] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { model in
                model.rawTargetMetric == targetMetric.rawValue
            },
            sortBy: [SortDescriptor(\Habit.startDate)]
        )
        return try context.fetch(descriptor).map { $0.asDTO() }
    }

    func fetchHabits(for targetMetric: TargetMetric, isSuggested: Bool) throws -> [HabitDTO] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { model in
                model.rawTargetMetric == targetMetric.rawValue && model.isSuggested == isSuggested
            },
            sortBy: [SortDescriptor(\Habit.startDate)]
        )
        return try context.fetch(descriptor).map { $0.asDTO() }
    }
}
