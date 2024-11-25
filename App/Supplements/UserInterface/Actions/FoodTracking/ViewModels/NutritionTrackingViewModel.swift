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

    func log(foodItemServings: [FoodItemServing], meal: FoodItemLog.Meal) throws {
        try modelContext.transaction {
            for serving in foodItemServings {
                let dbFoodItem: FoodItemRecord
                if let existingFoodItem = try modelContext.fetchFoodItem(for: serving.foodItem.id.value) {
                    dbFoodItem = existingFoodItem
                } else {
                    dbFoodItem = FoodItemRecord(foodItem: serving.foodItem)
                    modelContext.insert(dbFoodItem)
                }

                let foodItemLog = FoodItemLog(
                    id: UUID().uuidString,
                    date: .now, // TODO: this date needs to be computed based on the selected date + meal.
                    meal: meal,
                    numberOfServings: serving.serving,
                    foodItem: dbFoodItem
                )

                modelContext.insert(foodItemLog)
            }
        }
    }

    func log(
        foodItem: FoodItem,
        meal: FoodItemLog.Meal,
        numberOfServings: Double
    ) throws {
        let serving = FoodItemServing(serving: numberOfServings, foodItem: foodItem)
        try log(foodItemServings: [serving], meal: meal)
    }
}
