//
//  NutritionTrackingViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import SwiftUI
import SwiftData
import BloomModel
import DataContainer

@Observable @MainActor
final class NutritionTrackingViewModel {
    static let shared = NutritionTrackingViewModel()

    var suggestedMeal = FoodItemLog.Meal.breakfast // TODO: Make this change based on time of day

    private let modelContext = ModelContext(ContainerHolder.shared.container)

    private init() { }
}

extension NutritionTrackingViewModel {

    func log(
        foodItem: FoodItem,
        meal: FoodItemLog.Meal,
        numberOfServings: Double
    ) throws {
        try modelContext.transaction {
            let dbFoodItem: FoodItemRecord
            if let existingFoodItem = try modelContext.fetchFoodItem(for: foodItem.id.value) {
                dbFoodItem = existingFoodItem
            } else {
                dbFoodItem = FoodItemRecord(foodItem: foodItem)
                modelContext.insert(dbFoodItem)
            }

            let foodItemLog = FoodItemLog(
                id: UUID().uuidString,
                date: .now, // TODO: this date needs to be computed based on the selected date + meal.
                meal: meal,
                numberOfServings: numberOfServings,
                foodItem: dbFoodItem
            )

            modelContext.insert(foodItemLog)
        }
    }
}
