//
//  NutritionData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import DataContainer
import HealthKit
import CoreNetwork

struct NutritionData: SendableNetworkModel {
  let totalCalories: String
  let protein: String?
  let carbohydrates: String?
  let fat: String?
  let saturatedFat: String?
  let fiber: String?
  let sugar: String?
  let sodium: String?
  let hydration: MetricWithTrend?

  let meals: [MealData]
}

struct MealData: SendableNetworkModel {
  let mealType: String
  let foodItems: [FoodItemData]
  let totalCalories: String
}

struct FoodItemData: SendableNetworkModel {
  let name: String
  let brandName: String
  let calories: String
  let protein: String
  let carbohydrates: String
  let fat: String
  let saturatedFat: String?
  let transFat: String?
  let polyunsaturatedFat: String?
  let monounsaturatedFat: String?
  let fiber: String?
  let sugar: String?
  let cholesterol: String?
  let sodium: String?
  let calcium: String?
  let iron: String?
  let potassium: String?
  let magnesium: String?
  let zinc: String?
  let vitaminA: String?
  let vitaminB6: String?
  let vitaminB12: String?
  let vitaminC: String?
  let vitaminD: String?
  let vitaminE: String?
  let ingredients: String?
}

extension FoodItemData {
  
  init(foodItemLog: FoodItemLogDTO, foodItem: FoodItemDTO) {
    func optionalQuantity(
      foodItemLog: FoodItemLogDTO,
      foodItem: FoodItemDTO,
      keyPath: KeyPath<FoodItemDTO, Double?>,
      storedUnit: HKUnit,
      desiredUnit: HKUnit,
      numberFormatter: NumberFormatter
    ) -> String? {
      guard
        let value = foodItemLog.totalNutrient(foodItem: foodItem, keyPath: keyPath),
        value > 0
      else { return nil }

      let quantity = HKQuantity(unit: storedUnit, doubleValue: value)
      let desiredValue = quantity.doubleValue(for: desiredUnit)

      guard let format = numberFormatter.string(for: desiredValue) else { return nil }

      return "\(format) \(desiredUnit.unitString)"
    }

    self.init(
      name: foodItem.name,
      brandName: foodItem.brandName,
      calories: foodItemLog.totalNutrient(foodItem: foodItem, keyPath: \.calories, unit: "Cal"),
      protein: foodItemLog.totalNutrient(foodItem: foodItem, keyPath: \.protein, unit: "g"),
      carbohydrates: foodItemLog.totalNutrient(foodItem: foodItem, keyPath: \.carbohydrates, unit: "g"),
      fat: foodItemLog.totalNutrient(foodItem: foodItem, keyPath: \.fat, unit: "g"),
      saturatedFat: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.saturatedFat,
        storedUnit: .gram(),
        desiredUnit: .gram(),
        numberFormatter: .noDecimalPlaces
      ),
      transFat: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.transFat,
        storedUnit: .gram(),
        desiredUnit: .gram(),
        numberFormatter: .noDecimalPlaces
      ),
      polyunsaturatedFat: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.polyunsaturatedFat,
        storedUnit: .gram(),
        desiredUnit: .gram(),
        numberFormatter: .noDecimalPlaces
      ),
      monounsaturatedFat: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.monounsaturatedFat,
        storedUnit: .gram(),
        desiredUnit: .gram(),
        numberFormatter: .noDecimalPlaces
      ),
      fiber: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.fiber,
        storedUnit: .gram(),
        desiredUnit: .gram(),
        numberFormatter: .noDecimalPlaces
      ),
      sugar: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.sugar,
        storedUnit: .gram(),
        desiredUnit: .gram(),
        numberFormatter: .noDecimalPlaces
      ),
      cholesterol: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.cholesterol,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .milli),
        numberFormatter: .threeDecimalPlaces
      ),
      sodium: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.sodium,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .milli),
        numberFormatter: .threeDecimalPlaces
      ),
      calcium: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.calcium,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .milli),
        numberFormatter: .threeDecimalPlaces
      ),
      iron: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.iron,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .milli),
        numberFormatter: .threeDecimalPlaces
      ),
      potassium: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.potassium,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .milli),
        numberFormatter: .threeDecimalPlaces
      ),
      magnesium: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.magnesium,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .milli),
        numberFormatter: .threeDecimalPlaces
      ),
      zinc: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.zinc,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .milli),
        numberFormatter: .threeDecimalPlaces
      ),
      vitaminA: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.vitaminA,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .micro),
        numberFormatter: .threeDecimalPlaces
      ),
      vitaminB6: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.vitaminB6,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .milli),
        numberFormatter: .threeDecimalPlaces
      ),
      vitaminB12: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.vitaminB12,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .micro),
        numberFormatter: .threeDecimalPlaces
      ),
      vitaminC: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.vitaminC,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .milli),
        numberFormatter: .threeDecimalPlaces
      ),
      vitaminD: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.vitaminD,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .micro),
        numberFormatter: .threeDecimalPlaces
      ),
      vitaminE: optionalQuantity(
        foodItemLog: foodItemLog,
        foodItem: foodItem,
        keyPath: \.vitaminE,
        storedUnit: .gramUnit(with: .milli),
        desiredUnit: .gramUnit(with: .milli),
        numberFormatter: .threeDecimalPlaces
      ),
      ingredients: foodItem.ingredients
    )
  }
}