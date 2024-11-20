//
//  FoodItemLogModelActor.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
import SwiftData

@ModelActor
public final actor FoodItemLogModelActor: SharedModelActor {

    private var context: ModelContext { modelExecutor.modelContext }
}

public extension FoodItemLogModelActor {

    func fetchLogs(for date: Date) throws -> [FoodItemLogDTO] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.endOfDay(for: date)

        let descriptor = FetchDescriptor<FoodItemLog>(
            predicate: #Predicate<FoodItemLog> { model in
                model.date >= startOfDay && model.date <= endOfDay
            },
            sortBy: [SortDescriptor(\FoodItemLog.date)]
        )
        return try context.fetch(descriptor).map { $0.asDTO() }
    }

    func fetchLogs(for date: Date, meal: FoodItemLog.Meal) throws -> [FoodItemLogDTO] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.endOfDay(for: date)

        let descriptor = FetchDescriptor<FoodItemLog>(
            predicate: #Predicate<FoodItemLog> { model in
                model.date >= startOfDay &&
                model.date <= endOfDay &&
                model.meal == meal
            },
            sortBy: [SortDescriptor(\FoodItemLog.date)]
        )
        return try context.fetch(descriptor).map { $0.asDTO() }
    }
}
