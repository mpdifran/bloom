//
//  NutrientsRemainingViewModel.swift
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
final class NutrientsRemainingViewModel: ObservableObject {
  var title: String {
    // If no goals are set, just display total Nutrients
    calorieGoalQuantity != nil ? "Nutrients Remaining" : "Total Nutrients"
  }

  // MARK: Published Quantities

  @Published private var caloriesQuantity = HKQuantity(
    unit: FoodItemNutrient.calories.unit,
    doubleValue: 0
  )
  @Published private var proteinQuantity = HKQuantity(
    unit: FoodItemNutrient.protein.unit,
    doubleValue: 0
  )
  @Published private var fatsQuantity = HKQuantity(
    unit: FoodItemNutrient.fat.unit,
    doubleValue: 0
  )
  @Published private var carbsQuantity = HKQuantity(
    unit: FoodItemNutrient.carbohydrates.unit,
    doubleValue: 0
  )

  @Published private var calorieGoalQuantity: HKQuantity?
  @Published private var proteinGoalQuantity: HKQuantity?

  // MARK: Quantity Values

  /// Not needed by the UI but used in calculations.
  private var caloriesValue: Double {
    caloriesQuantity.doubleValue(for: FoodItemNutrient.calories.unit)
  }

  var proteinValue: Double {
    proteinQuantity.doubleValue(for: FoodItemNutrient.protein.unit)
  }

  var fatsValue: Double {
    fatsQuantity.doubleValue(for: FoodItemNutrient.fat.unit)
  }

  var carbsValue: Double {
    carbsQuantity.doubleValue(for: FoodItemNutrient.carbohydrates.unit)
  }

  // MARK: Target Quantities

  private var fatsGoalQuantity: HKQuantity? {
    if let fatsTarget {
      HKQuantity(unit: FoodItemNutrient.fat.unit, doubleValue: fatsTarget)
    } else {
      nil
    }
  }

  private var carbsGoalQuantity: HKQuantity? {
    if let carbsTarget {
      HKQuantity(unit: FoodItemNutrient.carbohydrates.unit, doubleValue: carbsTarget)
    } else {
      nil
    }
  }

  // MARK: Target Values

  private var caloriesTarget: Double? {
    calorieGoalQuantity?.doubleValue(for: FoodItemNutrient.calories.unit)
  }

  var proteinTarget: Double? {
    proteinGoalQuantity?.doubleValue(for: FoodItemNutrient.protein.unit)
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

  // MARK: Display Strings

  var caloriesString: String {
    let quantity = if let calorieGoalQuantity {
      calorieGoalQuantity.subtract(caloriesQuantity, unit: FoodItemNutrient.calories.unit)
    } else {
      caloriesQuantity
    }

    return quantity.displayString(for: FoodItemNutrient.calories.unit, showUnits: false)
  }

  var proteinString: String {
    let quantity = if let proteinGoalQuantity {
      proteinGoalQuantity.subtract(proteinQuantity, unit: FoodItemNutrient.protein.unit)
    } else {
      proteinQuantity
    }

    return quantity.displayString(for: FoodItemNutrient.protein.unit)
  }

  var fatsString: String {
    let quantity = if let fatsGoalQuantity {
      fatsGoalQuantity.subtract(fatsQuantity, unit: FoodItemNutrient.fat.unit)
    } else {
      fatsQuantity
    }

    return quantity.displayString(for: FoodItemNutrient.fat.unit)
  }

  var carbsString: String {
    let quantity = if let carbsGoalQuantity {
      carbsGoalQuantity.subtract(carbsQuantity, unit: FoodItemNutrient.carbohydrates.unit)
    } else {
      carbsQuantity
    }

    return quantity.displayString(for: FoodItemNutrient.carbohydrates.unit)
  }

  private let modelActor = HabitModelActor.standard()

  private var nutrientObservationHandler: HKObserverQueryHandle?

  func observeChanges(for dateRange: DateRange) {
    nutrientObservationHandler = HealthManager.shared.healthStore.observeChanges(
      sampleTypes: [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietaryCarbohydrates),
      ],
      startDate: dateRange.start
    ) { [weak self] in
      await self?.calculateNutrients(for: dateRange)
    }
  }
}

private extension NutrientsRemainingViewModel {
  func calculateNutrients(for dateRange: DateRange) async {
    caloriesQuantity = await fetchNutrient(.calories, dateRange: dateRange)
    proteinQuantity = await fetchNutrient(.protein, dateRange: dateRange)
    fatsQuantity = await fetchNutrient(.fat, dateRange: dateRange)
    carbsQuantity = await fetchNutrient(.carbohydrates, dateRange: dateRange)

    if let calorieHabit = try? await modelActor.fetchActiveHabits(for: .calories).first {
      calorieGoalQuantity = calorieHabit.quantity

      // Only set the protein target if there's a calorie target
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

  func fetchNutrient(
    _ nutrient: FoodItemNutrient,
    dateRange: DateRange
  ) async -> HKQuantity {
    await HealthStoreFetcher.shared.fetchTotalQuantity(
      for: nutrient.identifier,
      dateRange: dateRange
    ) ?? HKQuantity(unit: nutrient.unit, doubleValue: 0)
  }
}
