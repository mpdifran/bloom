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

  func fetchFrequentLogs(for meal: FoodItemLog.Meal, limit: Int? = nil) throws -> [FoodItemLogDTO] {
    // Calculate 2 months ago.
    guard let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) else {
      return []
    }

    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate<FoodItemLog> { model in
        model.date >= twoMonthsAgo
        // TODO: Zach - we cannot query enums stored in SwiftData. Their rawValue must be on the model.
        // https://forums.developer.apple.com/forums/thread/735638
        // Do this in the V6 migration.
        // && model.mealRawValue == meal.rawValue
      }
    )

    let logs = try context.fetch(descriptor)

    // Count occurrences of each food item, sort by most frequent.
    var frequencyMap = Dictionary(grouping: logs, by: { $0.foodItem?.id })
      .compactMapValues { $0.count }
      .sorted { $0.value > $1.value }

    // If a limit is set, apply that to the mapping.
    if let limit {
      frequencyMap = Array(frequencyMap.prefix(limit))
    }

    // Map food logs in sorted order based on frequency.
    return frequencyMap.compactMap { foodItemID, _ in
      logs.first { $0.foodItem?.id == foodItemID }?.asDTO()
    }
  }
}
