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
  @Published var title: String = ""

  // TODO: Store as private HKQuantity and use computed values to expose string and doubles
  @Published var calorieTotal: Double = 0
  @Published var proteinTotal: Double = 0
  @Published var fatsTotal: Double = 0
  @Published var carbsTotal: Double = 0

  private let dateRange: DateRange

  private let modelActor = HabitModelActor.standard()

  private var nutrientObservationHandler: HKObserverQueryHandle?

  init(
    date: Date
  ) {
    self.dateRange = .duringDay(date)

    observeChanges()
  }
}

private extension NutrientsRemainingViewModel {
  func observeChanges() {
    nutrientObservationHandler = HealthManager.shared.healthStore.observeChanges(
      sampleTypes: [
        HKQuantityType(FoodItemNutrient.calories.identifier),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietaryCarbohydrates),
      ],
      startDate: dateRange.start
    ) { [weak self] in
      await self?.calculateNutrients()
    }
  }

  func calculateNutrients() async {
    await fetchCalories()
    await fetchProtein()
    await fetchFats()
    await fetchCarbs()
  }

  func fetchCalories() async {
    let nutrient = FoodItemNutrient.calories
    let quantity = await fetchNutrient(nutrient)

    calorieTotal = quantity.doubleValue(for: nutrient.unit)
  }

  func fetchProtein() async {
    let nutrient = FoodItemNutrient.protein
    let quantity = await fetchNutrient(nutrient)

    proteinTotal = quantity.doubleValue(for: nutrient.unit)
  }

  func fetchFats() async {
    let nutrient = FoodItemNutrient.fat
    let quantity = await fetchNutrient(nutrient)

    fatsTotal = quantity.doubleValue(for: nutrient.unit)
  }

  func fetchCarbs() async {
    let nutrient = FoodItemNutrient.carbohydrates
    let quantity = await fetchNutrient(nutrient)

    carbsTotal = quantity.doubleValue(for: nutrient.unit)
  }

  func fetchNutrient(_ nutrient: FoodItemNutrient) async -> HKQuantity {
    await HealthStoreFetcher.shared.fetchTotalQuantity(
      for: nutrient.identifier,
      dateRange: dateRange
    ) ?? HKQuantity(unit: nutrient.unit, doubleValue: 0)
  }
}
