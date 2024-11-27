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

    func fetchLog(for date: Date, meal: FoodItemLog.Meal, foodItemID: String) throws -> FoodItemLogDTO? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.endOfDay(for: date)

        let descriptor = FetchDescriptor<FoodItemLog>(
            predicate: #Predicate<FoodItemLog> { model in
                model.date >= startOfDay &&
                model.date <= endOfDay &&
                model.meal == meal &&
                model.foodItem?.id == foodItemID
            },
            sortBy: [SortDescriptor(\FoodItemLog.date)]
        )
        return try context.fetch(descriptor).first?.asDTO()
    }

    func fetchRecentLogs(for meal: FoodItemLog.Meal, limit: Int) throws -> [FoodItemLogDTO] {
        var descriptor = FetchDescriptor<FoodItemLog>(
//            predicate: #Predicate<FoodItemLog> { model in
//                model.meal == meal
//            },
            sortBy: [SortDescriptor(\FoodItemLog.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map { $0.asDTO() }
    }
}
