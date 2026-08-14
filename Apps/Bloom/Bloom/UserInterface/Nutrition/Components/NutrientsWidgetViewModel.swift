//
//  NutrientsWidgetViewModel.swift
//  Bloom
//
//  Created by Zach Radford on 2025-02-09.
//

import BloomFoundation
import DataContainer
import HealthKit
import SwiftUI
import CoreHealth

@MainActor
final class NutrientsWidgetViewModel: ObservableObject {
  var title: String {
    String(localized: "Macros", comment: "Title for nutrients widget view model")
  }

  // MARK: - Goal Quantities

  @Published private var calorieGoalQuantity: HKQuantity?
  @Published private var proteinGoalQuantity: HKQuantity?

  // MARK: Target Values

  var proteinTarget: Double? {
    proteinGoalQuantity?.doubleValue(for: FoodItemNutrient.protein.unit)
  }

  private var caloriesTarget: Double? {
    calorieGoalQuantity?.doubleValue(for: FoodItemNutrient.calories.unit)
  }

  private var remainingCaloriesSplit: Double? {
    if let caloriesTarget, let proteinTarget {
      let remaining = caloriesTarget - (proteinTarget * .caloriesPerGramOfProtein)
      return remaining / 2
    } else {
      return nil
    }
  }

  var fatsTarget: Double? {
    if let remainingCaloriesSplit {
      remainingCaloriesSplit / .caloriesPerGramOfFat
    } else {
      nil
    }
  }

  var carbsTarget: Double? {
    if let remainingCaloriesSplit {
      remainingCaloriesSplit / .caloriesPerGramOfCarbs
    } else {
      nil
    }
  }

  // MARK: - Goals

  private let modelActor = HabitModelActor.standard()

  func fetchGoals() async {
    if let calorieHabit = try? await modelActor.fetchActiveHabits(for: .calories).first {
      calorieGoalQuantity = calorieHabit.quantity

      if let proteinHabit = try? await modelActor.fetchActiveHabits(for: .proteinIntake).first {
        proteinGoalQuantity = proteinHabit.quantity
      } else {
        // If no protein goal is set but a calorie goal was set, assume 30% of calorie goal.
        let caloriesToProtein = calorieHabit.value / .caloriesPerGramOfProtein
        proteinGoalQuantity = HKQuantity(
          unit: FoodItemNutrient.protein.unit,
          doubleValue: caloriesToProtein * 0.3
        )
      }
    }
  }
}
