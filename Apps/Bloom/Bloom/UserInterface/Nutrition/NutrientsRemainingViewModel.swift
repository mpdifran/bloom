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

@MainActor
final class NutrientsRemainingViewModel: ObservableObject {
  var title: String {
    if calorieGoalQuantity != nil {
      "Nutrients Remaining"
    } else {
      "Nutrients"
    }
  }

  @Published private var calorieQuantity: HKQuantity = .init(
    unit: FoodItemNutrient.calories.unit,
    doubleValue: 0
  )
  var calorieString: String {
    calorieQuantity.displayString(for: FoodItemNutrient.calories.unit, showUnits: false)
  }

  @Published private var proteinQuantity: HKQuantity = .init(
    unit: FoodItemNutrient.protein.unit,
    doubleValue: 0
  )
  var proteinString: String {
    proteinQuantity.displayString(for: FoodItemNutrient.protein.unit)
  }
  var proteinValue: Double {
    proteinQuantity.doubleValue(for: FoodItemNutrient.protein.unit)
  }

  @Published private var fatsQuantity: HKQuantity = .init(
    unit: FoodItemNutrient.fat.unit,
    doubleValue: 0
  )
  var fatsString: String {
    fatsQuantity.displayString(for: FoodItemNutrient.fat.unit)
  }
  var fatsValue: Double {
    fatsQuantity.doubleValue(for: FoodItemNutrient.fat.unit)
  }

  @Published private var carbsQuantity: HKQuantity = .init(
    unit: FoodItemNutrient.carbohydrates.unit,
    doubleValue: 0
  )
  var carbsString: String {
    carbsQuantity.displayString(for: FoodItemNutrient.carbohydrates.unit)
  }
  var carbsValue: Double {
    carbsQuantity.doubleValue(for: FoodItemNutrient.carbohydrates.unit)
  }

  @Published private var calorieGoalQuantity: HKQuantity?
  private var calorieTarget: Double? {
    calorieGoalQuantity?.doubleValue(for: FoodItemNutrient.calories.unit)
  }

  @Published private var proteinGoalQuantity: HKQuantity?
  var proteinTarget: Double? {
    proteinGoalQuantity?.doubleValue(for: FoodItemNutrient.protein.unit)
  }

  var remainingTarget: Double? {
    if let calorieTarget, let proteinTarget {
      (calorieTarget - proteinTarget) / 2
    } else {
      nil
    }
  }

  private let modelActor = HabitModelActor.standard()

  private var nutrientObservationHandler: HKObserverQueryHandle?

  func observeChanges(for dateRange: DateRange) {
    nutrientObservationHandler = HealthManager.shared.healthStore.observeChanges(
      sampleTypes: [
        HKQuantityType(FoodItemNutrient.calories.identifier),
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
    calorieQuantity = await fetchNutrient(.calories, dateRange: dateRange)
    proteinQuantity = await fetchNutrient(.protein, dateRange: dateRange)
    fatsQuantity = await fetchNutrient(.fat, dateRange: dateRange)
    carbsQuantity = await fetchNutrient(.carbohydrates, dateRange: dateRange)

    let calorieHabit = try? await modelActor.fetchActiveHabits(for: .calories).first
    calorieGoalQuantity = calorieHabit?.quantity

    if let proteinHabit = try? await modelActor.fetchActiveHabits(for: .proteinIntake).first {
      proteinGoalQuantity = proteinHabit.quantity
    } else if let calorieHabit {
      // If no protein goal is set but a calorie goal was set, assume 30% of calorie goal.
      proteinGoalQuantity = HKQuantity(
        unit: FoodItemNutrient.protein.unit,
        doubleValue: calorieHabit.value * 0.3
      )
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
