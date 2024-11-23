//
//  NutritionTrackingViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import SwiftUI
import DataContainer

@Observable @MainActor
final class NutritionTrackingViewModel {

    var suggestedMeal = FoodItemLog.Meal.breakfast // TODO: Make this change based on time of day
}
