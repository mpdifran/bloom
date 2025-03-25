//
//  ChatHealthData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import Foundation
import DataContainer
import HealthKit

protocol SendableNetworkModel: Codable, Equatable, Sendable { }

// MARK: - ChatHealthData

struct ChatHealthData: SendableNetworkModel {
  let demographics: Demographics?
  let activityLevel: ActivityLevel?
  let bodyComposition: BodyComposition?
  let bowelMovements: BowelMovements?
  let exerciseEffectiveness: ExerciseEffectiveness?
  let heartHealth: HeartHealth?
  let menstrualHealth: MenstrualHealth?
  let nutrition: Nutrition?
  let sleep: Sleep?
  let stress: Stress?
}

extension ChatHealthData {
  var isEmpty: Bool {
    demographics == nil &&
    activityLevel == nil &&
    bodyComposition == nil &&
    bowelMovements == nil &&
    exerciseEffectiveness == nil &&
    heartHealth == nil &&
    menstrualHealth == nil &&
    sleep == nil &&
    stress == nil
  }
}

// MARK: - Primitives

extension ChatHealthData {
  struct Sample: SendableNetworkModel {
    let date: Date
    let quantity: Quantity
  }

  struct Quantity: SendableNetworkModel {
    let value: String
    let unit: String

    init(value: String, unit: String) {
      self.value = value
      self.unit = unit
    }

    init(value: Double, unit: String, numberFormatter: NumberFormatter) {
      self.value = numberFormatter.string(for: value) ?? ""
      self.unit = unit
    }
  }

  struct QuantityRange: SendableNetworkModel {
    let lower: Quantity
    let upper: Quantity
  }

  struct BowelMovementSample: SendableNetworkModel {
    let date: Date
    let bristolStoolType: Int
    let duration: String
  }

  struct FoodLogDay: SendableNetworkModel {
    let date: Date
    let breakfast: [FoodItem]
    let lunch: [FoodItem]
    let dinner: [FoodItem]
    let snack: [FoodItem]
  }

  struct FoodItem: SendableNetworkModel {
    let name: String
    let brandName: String
    let calories: Quantity
    let protein: Quantity
    let carbohydrates: Quantity
    let fat: Quantity
    let saturatedFat: Quantity?
    let transFat: Quantity?
    let polyunsaturatedFat: Quantity?
    let monounsaturatedFat: Quantity?
    let fiber: Quantity?
    let sugar: Quantity?
    let cholesterol: Quantity?
    let sodium: Quantity?
    let calcium: Quantity?
    let iron: Quantity?
    let potassium: Quantity?
    let magnesium: Quantity?
    let zinc: Quantity?
    let vitaminA: Quantity?
    let vitaminB6: Quantity?
    let vitaminB12: Quantity?
    let vitaminC: Quantity?
    let vitaminD: Quantity?
    let vitaminE: Quantity?
    let ingredients: String?
  }

  struct HeartRateZones: SendableNetworkModel {
    let heartRateReserve: Quantity
    let restingHeartRate: Quantity
    let maxHeartRate: Quantity
    let zone1: QuantityRange
    let zone2: QuantityRange
    let zone3: QuantityRange
    let zone4: QuantityRange
    let zone5: QuantityRange
  }

  struct HeartRateZoneWorkoutSample: SendableNetworkModel {
    let date: Date
    let workout: String
    let workoutDuration: Quantity
    let zone1Duration: Quantity
    let zone2Duration: Quantity
    let zone3Duration: Quantity
    let zone4Duration: Quantity
    let zone5Duration: Quantity
  }

  struct MenstrualCycle: SendableNetworkModel {
    let startDate: Date
    let flowSamples: [MenstrualFlowLevelSample]
  }

  struct MenstrualFlowLevelSample: SendableNetworkModel {
    let date: Date
    let flowLevel: FlowLevel

    enum FlowLevel: String, SendableNetworkModel {
      case none
      case light
      case medium
      case heavy
    }
  }

  struct SleepDay: SendableNetworkModel {
    let startDate: Date
    let endDate: Date
    let deepSleep: Quantity?
    let coreSleep: Quantity?
    let remSleep: Quantity?
    let awakeSleep: Quantity?
    let averageHeartRate: Quantity?
    let averageRespiratoryRate: Quantity?
    let averageDecibelAWeightedEnvironmentalSoundPressureLevel: Quantity?
    let wristTemperature: Quantity?
  }

  struct BloodPressureSample: SendableNetworkModel {
    let date: Date
    let systolic: Quantity
    let diastolic: Quantity
  }
}

extension ChatHealthData.FoodItem {

  init(foodItemLog: FoodItemLogDTO, foodItem: FoodItemDTO) {
    func optionalQuantity(
      foodItemLog: FoodItemLogDTO,
      foodItem: FoodItemDTO,
      keyPath: KeyPath<FoodItemDTO, Double?>,
      storedUnit: HKUnit,
      desiredUnit: HKUnit,
      numberFormatter: NumberFormatter
    ) -> ChatHealthData.Quantity? {
      guard
        let value = foodItemLog.totalNutrient(foodItem: foodItem, keyPath: keyPath),
        value > 0
      else { return nil }

      let quantity = HKQuantity(unit: storedUnit, doubleValue: value)

      return ChatHealthData.Quantity(
        value: quantity.doubleValue(for: desiredUnit),
        unit: desiredUnit.unitString,
        numberFormatter: numberFormatter
      )
    }

    self.init(
      name: foodItem.name,
      brandName: foodItem.brandName,
      calories: ChatHealthData.Quantity(
        value: foodItemLog.totalNutrient(foodItem: foodItem, keyPath: \.calories),
        unit: "Cal",
        numberFormatter: .noDecimalPlaces
      ),
      protein: ChatHealthData.Quantity(
        value: foodItemLog.totalNutrient(foodItem: foodItem, keyPath: \.protein),
        unit: "g",
        numberFormatter: .noDecimalPlaces
      ),
      carbohydrates: ChatHealthData.Quantity(
        value: foodItemLog.totalNutrient(foodItem: foodItem, keyPath: \.carbohydrates),
        unit: "g",
        numberFormatter: .noDecimalPlaces
      ),
      fat: ChatHealthData.Quantity(
        value: foodItemLog.totalNutrient(foodItem: foodItem, keyPath: \.fat),
        unit: "g",
        numberFormatter: .noDecimalPlaces
      ),
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

// MARK: - Demographics

extension ChatHealthData {
  struct Demographics: SendableNetworkModel {
    let age: Int?
    let sex: String?
    let height: Quantity?
    let healthGoal: String?
  }
}

// MARK: - Activity Level

extension ChatHealthData {
  struct ActivityLevel: SendableNetworkModel {
    let basalEnergyBurned: [Sample]
    let activeEnergyBurned: [Sample]
  }
}

// MARK: - Body Composition

extension ChatHealthData {
  struct BodyComposition: SendableNetworkModel {
    let bodyFatPercentage: [Sample]
    let bodyMass: [Sample]
  }
}

// MARK: - Bowel Movement

extension ChatHealthData {
  struct BowelMovements: SendableNetworkModel {
    let samples: [BowelMovementSample]
  }
}

// MARK: - Exercise Effectiveness

extension ChatHealthData {
  struct ExerciseEffectiveness: SendableNetworkModel {
    let heartRateZones: HeartRateZones
    let heartRateZoneWorkoutSamples: [HeartRateZoneWorkoutSample]
  }
}

// MARK: - Heart Health

extension ChatHealthData {
  struct HeartHealth: SendableNetworkModel {
    let vo2Max: [Sample]
    let restingHeartRate: [Sample]
    let heartRateRecoveryOneMinute: [Sample]
  }
}

// MARK: - Menstrual Health

extension ChatHealthData {
  struct MenstrualHealth: SendableNetworkModel {
    let cycles: [MenstrualCycle]
  }
}

// MARK: - Nutrition

extension ChatHealthData {
  struct Nutrition: SendableNetworkModel {
    let foodLogs: [FoodLogDay]
  }
}

// MARK: - Sleep

extension ChatHealthData {
  struct Sleep: SendableNetworkModel {
    let sleepDetails: [SleepDay]
  }
}

// MARK: - Stress

extension ChatHealthData {
  struct Stress: SendableNetworkModel {
    let heartRateVariability: [Sample]
    let bloodPressureSamples: [BloodPressureSample]
  }
}
