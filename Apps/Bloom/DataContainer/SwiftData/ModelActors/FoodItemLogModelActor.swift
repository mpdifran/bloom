//
//  FoodItemLogModelActor.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import BloomFoundation
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

  func fetchLogs(for dateRange: DateRange) throws -> [FoodItemLogDTO] {
    let startOfDay = Calendar.current.startOfDay(for: dateRange.start)
    let endOfDay = Calendar.current.endOfDay(for: dateRange.end)

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
    let mealRawValue = meal.rawValue

    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate<FoodItemLog> { model in
        model.date >= startOfDay &&
        model.date <= endOfDay &&
        model.mealRawValue == mealRawValue
      },
      sortBy: [SortDescriptor(\FoodItemLog.date)]
    )
    let logs = try context.fetch(descriptor)

    // foodItem is no longer on the log so we can't use it in a predicate.
    let filteredLogs = logs.filter { $0.foodItem?.id == foodItemID }

    return filteredLogs.first?.asDTO()
  }

  func fetchRecentLogs(
    for meal: FoodItemLog.Meal?,
    dateRange: DateRange = DateRange.trailingMonthsFromNow(1)
  ) throws -> [FoodItemDTO] {
    let startDate = dateRange.start
    let endDate = dateRange.end

    let descriptor: FetchDescriptor<FoodItemLog>
    if let mealRawValue = meal?.rawValue {
      descriptor = FetchDescriptor<FoodItemLog>(
        predicate: #Predicate<FoodItemLog> { model in
          model.date >= startDate &&
          model.date <= endDate &&
          model.mealRawValue == mealRawValue
        },
        sortBy: [SortDescriptor(\FoodItemLog.date, order: .reverse)]
      )
    } else {
      descriptor = FetchDescriptor<FoodItemLog>(
        predicate: #Predicate<FoodItemLog> { model in
          model.date >= startDate &&
          model.date <= endDate
        },
        sortBy: [SortDescriptor(\FoodItemLog.date, order: .reverse)]
      )
    }

    let results = try context.fetch(descriptor)

    return results
      .compactMap { $0.foodItemServings }
      .flatMap { $0 }
      .compactMap { $0.foodItem?.asDTO() }
  }

  func fetchFrequentLogs(
    for meal: FoodItemLog.Meal?,
    dateRange: DateRange = DateRange.trailingMonthsFromNow(2)
  ) throws -> [FoodItemDTO] {
    let startDate = dateRange.start
    let endDate = dateRange.end

    let descriptor: FetchDescriptor<FoodItemLog>
    if let mealRawValue = meal?.rawValue {
      descriptor = FetchDescriptor<FoodItemLog>(
        predicate: #Predicate<FoodItemLog> { model in
          model.date >= startDate &&
          model.date <= endDate &&
          model.mealRawValue == mealRawValue
        }
      )
    } else {
      descriptor = FetchDescriptor<FoodItemLog>(
        predicate: #Predicate<FoodItemLog> { model in
          model.date >= startDate &&
          model.date <= endDate
        }
      )
    }

    let logs = try context.fetch(descriptor)

    // Flatten all servings across logs, extract FoodItems, and count frequency.
    let allServings = logs.flatMap { $0.foodItemServings ?? [] }
    let frequencyMap = Dictionary(grouping: allServings, by: { $0.foodItem?.id })
      .compactMapValues { ($0.first?.foodItem, $0.count) }
      .sorted { $0.value.1 > $1.value.1 }

    // Map food items in sorted order based on frequency.
    return frequencyMap.compactMap { (foodItemID, value) in
      value.0?.asDTO()
    }
  }

  func fetchFoodItem(for id: String) throws -> FoodItemDTO? {
    let descriptor = FetchDescriptor<FoodItemRecord>(
      predicate: #Predicate<FoodItemRecord> { model in
        model.id == id
      }
    )
    return try context.fetch(descriptor).first?.asDTO()
  }
}
