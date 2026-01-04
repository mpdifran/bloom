//
//  HealthVitalData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import Foundation
import DataContainer
import HealthKit
import BloomFoundation

public protocol SendableNetworkModel: Codable, Equatable, Sendable { }

// MARK: - HealthVitalData

public struct HealthVitalData: SendableNetworkModel {
  public let activityLevel: ActivityLevel?
  public let bodyComposition: BodyComposition?
  public let bowelMovements: BowelMovements?
  public let exerciseEffectiveness: ExerciseEffectiveness?
  public let heartHealth: HeartHealth?
  public let menstrualHealth: MenstrualHealth?
  public let nutrition: Nutrition?
  public let sleep: Sleep?
  public let stress: Stress?

  public init(
    activityLevel: ActivityLevel?,
    bodyComposition: BodyComposition?,
    bowelMovements: BowelMovements?,
    exerciseEffectiveness: ExerciseEffectiveness?,
    heartHealth: HeartHealth?,
    menstrualHealth: MenstrualHealth?,
    nutrition: Nutrition?,
    sleep: Sleep?,
    stress: Stress?
  ) {
    self.activityLevel = activityLevel
    self.bodyComposition = bodyComposition
    self.bowelMovements = bowelMovements
    self.exerciseEffectiveness = exerciseEffectiveness
    self.heartHealth = heartHealth
    self.menstrualHealth = menstrualHealth
    self.nutrition = nutrition
    self.sleep = sleep
    self.stress = stress
  }
}

extension HealthVitalData {
  public var isEmpty: Bool {
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

extension HealthVitalData {
  public struct Sample: SendableNetworkModel {
    public let date: Date
    public let quantity: Quantity

    public init(date: Date, quantity: Quantity) {
      self.date = date
      self.quantity = quantity
    }
  }

  public struct Quantity: SendableNetworkModel {
    public let value: String
    public let unit: String

    public init(value: String, unit: String) {
      self.value = value
      self.unit = unit
    }

    public init(value: Double, unit: String, numberFormatter: NumberFormatter) {
      self.value = numberFormatter.string(for: value) ?? ""
      self.unit = unit
    }
  }

  public struct QuantityRange: SendableNetworkModel {
    public let lower: Quantity
    public let upper: Quantity

    public init(lower: Quantity, upper: Quantity) {
      self.lower = lower
      self.upper = upper
    }
  }

  public struct BowelMovementSample: SendableNetworkModel {
    public let date: Date
    public let bristolStoolType: Int
    public let duration: String

    public init(date: Date, bristolStoolType: Int, duration: String) {
      self.date = date
      self.bristolStoolType = bristolStoolType
      self.duration = duration
    }
  }

  public struct FoodLogDay: SendableNetworkModel {
    public let date: String
    public let breakfast: [FoodItem]
    public let lunch: [FoodItem]
    public let dinner: [FoodItem]
    public let snack: [FoodItem]

    public init(date: String, breakfast: [FoodItem], lunch: [FoodItem], dinner: [FoodItem], snack: [FoodItem]) {
      self.date = date
      self.breakfast = breakfast
      self.lunch = lunch
      self.dinner = dinner
      self.snack = snack
    }
  }

  public struct FoodItem: SendableNetworkModel {
    public let name: String
    public let brandName: String
    public let calories: String
    public let protein: String
    public let carbohydrates: String
    public let fat: String
    public let saturatedFat: String?
    public let transFat: String?
    public let polyunsaturatedFat: String?
    public let monounsaturatedFat: String?
    public let fiber: String?
    public let sugar: String?
    public let cholesterol: String?
    public let sodium: String?
    public let calcium: String?
    public let iron: String?
    public let potassium: String?
    public let magnesium: String?
    public let zinc: String?
    public let vitaminA: String?
    public let vitaminB6: String?
    public let vitaminB12: String?
    public let vitaminC: String?
    public let vitaminD: String?
    public let vitaminE: String?
    public let ingredients: String?
  }

  public struct NutritionAverages: SendableNetworkModel {
    public let averageProtein: String?
    public let averageCarbohydrates: String?
    public let averageFat: String?
    public let averageSaturatedFat: String?
    public let averagePolyunsaturatedFat: String?
    public let averageMonounsaturatedFat: String?
    public let averageFiber: String?
    public let averageSugar: String?
    public let averageCholesterol: String?
    public let averageCalcium: String?
    public let averageIron: String?
    public let averageMagnesium: String?
    public let averagePotassium: String?
    public let averageSodium: String?
    public let averageZinc: String?
    public let averageVitaminA: String?
    public let averageVitaminB6: String?
    public let averageVitaminB12: String?
    public let averageVitaminC: String?
    public let averageVitaminD: String?
    public let averageVitaminE: String?

    public init(
      averageProtein: String?,
      averageCarbohydrates: String?,
      averageFat: String?,
      averageSaturatedFat: String?,
      averagePolyunsaturatedFat: String?,
      averageMonounsaturatedFat: String?,
      averageFiber: String?,
      averageSugar: String?,
      averageCholesterol: String?,
      averageCalcium: String?,
      averageIron: String?,
      averageMagnesium: String?,
      averagePotassium: String?,
      averageSodium: String?,
      averageZinc: String?,
      averageVitaminA: String?,
      averageVitaminB6: String?,
      averageVitaminB12: String?,
      averageVitaminC: String?,
      averageVitaminD: String?,
      averageVitaminE: String?
    ) {
      self.averageProtein = averageProtein
      self.averageCarbohydrates = averageCarbohydrates
      self.averageFat = averageFat
      self.averageSaturatedFat = averageSaturatedFat
      self.averagePolyunsaturatedFat = averagePolyunsaturatedFat
      self.averageMonounsaturatedFat = averageMonounsaturatedFat
      self.averageFiber = averageFiber
      self.averageSugar = averageSugar
      self.averageCholesterol = averageCholesterol
      self.averageCalcium = averageCalcium
      self.averageIron = averageIron
      self.averageMagnesium = averageMagnesium
      self.averagePotassium = averagePotassium
      self.averageSodium = averageSodium
      self.averageZinc = averageZinc
      self.averageVitaminA = averageVitaminA
      self.averageVitaminB6 = averageVitaminB6
      self.averageVitaminB12 = averageVitaminB12
      self.averageVitaminC = averageVitaminC
      self.averageVitaminD = averageVitaminD
      self.averageVitaminE = averageVitaminE
    }
  }

  public struct HeartRateZones: SendableNetworkModel {
    public let heartRateReserve: Quantity
    public let restingHeartRate: Quantity
    public let maxHeartRate: Quantity
    public let zone1: QuantityRange
    public let zone2: QuantityRange
    public let zone3: QuantityRange
    public let zone4: QuantityRange
    public let zone5: QuantityRange

    public init(
      heartRateReserve: Quantity,
      restingHeartRate: Quantity,
      maxHeartRate: Quantity,
      zone1: QuantityRange,
      zone2: QuantityRange,
      zone3: QuantityRange,
      zone4: QuantityRange,
      zone5: QuantityRange
    ) {
      self.heartRateReserve = heartRateReserve
      self.restingHeartRate = restingHeartRate
      self.maxHeartRate = maxHeartRate
      self.zone1 = zone1
      self.zone2 = zone2
      self.zone3 = zone3
      self.zone4 = zone4
      self.zone5 = zone5
    }
  }

  public struct HeartRateZoneWorkoutSample: SendableNetworkModel {
    public let start: Date
    public let end: Date
    public let workout: String
    public let workoutDuration: Quantity
    public let zone1Duration: Quantity
    public let zone2Duration: Quantity
    public let zone3Duration: Quantity
    public let zone4Duration: Quantity
    public let zone5Duration: Quantity

    public init(
      start: Date,
      end: Date,
      workout: String,
      workoutDuration: Quantity,
      zone1Duration: Quantity,
      zone2Duration: Quantity,
      zone3Duration: Quantity,
      zone4Duration: Quantity,
      zone5Duration: Quantity
    ) {
      self.start = start
      self.end = end
      self.workout = workout
      self.workoutDuration = workoutDuration
      self.zone1Duration = zone1Duration
      self.zone2Duration = zone2Duration
      self.zone3Duration = zone3Duration
      self.zone4Duration = zone4Duration
      self.zone5Duration = zone5Duration
    }
  }

  public struct MenstrualCycle: SendableNetworkModel {
    public let startDate: Date
    public let flowSamples: [MenstrualFlowLevelSample]

    public init(startDate: Date, flowSamples: [MenstrualFlowLevelSample]) {
      self.startDate = startDate
      self.flowSamples = flowSamples
    }
  }

  public struct MenstrualFlowLevelSample: SendableNetworkModel {
    public let date: Date
    public let flowLevel: FlowLevel

    public enum FlowLevel: String, SendableNetworkModel {
      case none
      case light
      case medium
      case heavy
    }

    public init(date: Date, flowLevel: FlowLevel) {
      self.date = date
      self.flowLevel = flowLevel
    }
  }

  public struct SleepDay: SendableNetworkModel {
    public let start: Date
    public let end: Date
    public let deepSleep: Quantity?
    public let coreSleep: Quantity?
    public let remSleep: Quantity?
    public let awakeSleep: Quantity?
    public let averageHeartRate: Quantity?
    public let averageRespiratoryRate: Quantity?
    public let averageDecibelAWeightedEnvironmentalSoundPressureLevel: Quantity?
    public let wristTemperature: Quantity?

    public init(
      start: Date,
      end: Date,
      deepSleep: Quantity?,
      coreSleep: Quantity?,
      remSleep: Quantity?,
      awakeSleep: Quantity?,
      averageHeartRate: Quantity?,
      averageRespiratoryRate: Quantity?,
      averageDecibelAWeightedEnvironmentalSoundPressureLevel: Quantity?,
      wristTemperature: Quantity?
    ) {
      self.start = start
      self.end = end
      self.deepSleep = deepSleep
      self.coreSleep = coreSleep
      self.remSleep = remSleep
      self.awakeSleep = awakeSleep
      self.averageHeartRate = averageHeartRate
      self.averageRespiratoryRate = averageRespiratoryRate
      self.averageDecibelAWeightedEnvironmentalSoundPressureLevel = averageDecibelAWeightedEnvironmentalSoundPressureLevel
      self.wristTemperature = wristTemperature
    }
  }

  public struct BloodPressureSample: SendableNetworkModel {
    public let date: Date
    public let systolic: Quantity
    public let diastolic: Quantity

    public init(date: Date, systolic: Quantity, diastolic: Quantity) {
      self.date = date
      self.systolic = systolic
      self.diastolic = diastolic
    }
  }
}

extension HealthVitalData.FoodItem {

  public init(foodItemLog: FoodItemLogDTO, foodItem: FoodItemDTO) {
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

// MARK: - UserInfo

extension HealthVitalData {
  public struct DateTime: SendableNetworkModel {
    public let currentDate: String
    public let timeZone: String

    public init(currentDate: String, timeZone: String) {
      self.currentDate = currentDate
      self.timeZone = timeZone
    }
  }

  public struct ChatContext: SendableNetworkModel {
    public let userInfo: UserInfo?
    public let dateTime: DateTime

    public init(userInfo: UserInfo?, dateTime: DateTime) {
      self.userInfo = userInfo
      self.dateTime = dateTime
    }
  }

  public struct UserInfo: SendableNetworkModel {
    public let age: Int?
    public let sex: String?
    public let height: String?
    public let focus: String?
    public let location: String?
    public let workoutEquipment: [String]
    public let userFacts: [ChatUserFactsData.UserFact]

    public init(
      age: Int?,
      sex: String?,
      height: String?,
      focus: String?,
      location: String?,
      workoutEquipment: [String],
      userFacts: [ChatUserFactsData.UserFact]
    ) {
      self.age = age
      self.sex = sex
      self.height = height
      self.focus = focus
      self.location = location
      self.workoutEquipment = workoutEquipment
      self.userFacts = userFacts
    }
  }
}

// MARK: - Activity Level

extension HealthVitalData {
  public struct ActivityLevel: SendableNetworkModel {
    public let basalEnergyBurned: [Sample]
    public let activeEnergyBurned: [Sample]
    public let bioAgeSummary: BioAgeSummary?

    public init(
      basalEnergyBurned: [Sample],
      activeEnergyBurned: [Sample],
      bioAgeSummary: BioAgeSummary? = nil
    ) {
      self.basalEnergyBurned = basalEnergyBurned
      self.activeEnergyBurned = activeEnergyBurned
      self.bioAgeSummary = bioAgeSummary
    }
  }
}

// MARK: - Body Composition

extension HealthVitalData {
  public struct BodyComposition: SendableNetworkModel {
    public let bodyFatPercentage: [Sample]
    public let bodyMass: [Sample]
    public let bioAgeSummary: BioAgeSummary?

    public init(
      bodyFatPercentage: [Sample],
      bodyMass: [Sample],
      bioAgeSummary: BioAgeSummary? = nil
    ) {
      self.bodyFatPercentage = bodyFatPercentage
      self.bodyMass = bodyMass
      self.bioAgeSummary = bioAgeSummary
    }
  }
}

// MARK: - Bowel Movement

extension HealthVitalData {
  public struct BowelMovements: SendableNetworkModel {
    public let samples: [BowelMovementSample]
    public let bioAgeSummary: BioAgeSummary?

    public init(samples: [BowelMovementSample], bioAgeSummary: BioAgeSummary? = nil) {
      self.samples = samples
      self.bioAgeSummary = bioAgeSummary
    }
  }
}

// MARK: - Exercise Effectiveness

extension HealthVitalData {
  public struct ExerciseEffectiveness: SendableNetworkModel {
    public let heartRateZones: HeartRateZones
    public let heartRateZoneWorkoutSamples: [HeartRateZoneWorkoutSample]

    public init(heartRateZones: HeartRateZones, heartRateZoneWorkoutSamples: [HeartRateZoneWorkoutSample]) {
      self.heartRateZones = heartRateZones
      self.heartRateZoneWorkoutSamples = heartRateZoneWorkoutSamples
    }
  }
}

// MARK: - Heart Health

extension HealthVitalData {
  public struct HeartHealth: SendableNetworkModel {
    public let vo2Max: [Sample]
    public let restingHeartRate: [Sample]
    public let heartRateRecoveryOneMinute: [Sample]
    public let bioAgeSummary: BioAgeSummary?

    public init(
      vo2Max: [Sample],
      restingHeartRate: [Sample],
      heartRateRecoveryOneMinute: [Sample],
      bioAgeSummary: BioAgeSummary? = nil
    ) {
      self.vo2Max = vo2Max
      self.restingHeartRate = restingHeartRate
      self.heartRateRecoveryOneMinute = heartRateRecoveryOneMinute
      self.bioAgeSummary = bioAgeSummary
    }
  }
}

// MARK: - Menstrual Health

extension HealthVitalData {
  public struct MenstrualHealth: SendableNetworkModel {
    public let cycles: [MenstrualCycle]

    public init(cycles: [MenstrualCycle]) {
      self.cycles = cycles
    }
  }
}

// MARK: - Nutrition

extension HealthVitalData {
  public struct Nutrition: SendableNetworkModel {
    public let nutritionAverages: HealthVitalData.NutritionAverages
    public let foodLogs: [FoodLogDay]
    public let bioAgeSummary: BioAgeSummary?

    public init(
      nutritionAverages: HealthVitalData.NutritionAverages,
      foodLogs: [FoodLogDay],
      bioAgeSummary: BioAgeSummary? = nil
    ) {
      self.nutritionAverages = nutritionAverages
      self.foodLogs = foodLogs
      self.bioAgeSummary = bioAgeSummary
    }
  }
}

// MARK: - Sleep

extension HealthVitalData {
  public struct Sleep: SendableNetworkModel {
    public let sleepDetails: [SleepDay]
    public let bioAgeSummary: BioAgeSummary?

    public init(sleepDetails: [SleepDay], bioAgeSummary: BioAgeSummary? = nil) {
      self.sleepDetails = sleepDetails
      self.bioAgeSummary = bioAgeSummary
    }
  }
}

// MARK: - Stress

extension HealthVitalData {
  public struct Stress: SendableNetworkModel {
    public let heartRateVariability: [Sample]
    public let bloodPressureSamples: [BloodPressureSample]
    public let bioAgeSummary: BioAgeSummary?

    public init(
      heartRateVariability: [Sample],
      bloodPressureSamples: [BloodPressureSample],
      bioAgeSummary: BioAgeSummary? = nil
    ) {
      self.heartRateVariability = heartRateVariability
      self.bloodPressureSamples = bloodPressureSamples
      self.bioAgeSummary = bioAgeSummary
    }
  }
}

// MARK: - Workouts

extension HealthVitalData {
  public struct Workout: SendableNetworkModel {
    public let name: String
    public let start: Date
    public let end: Date
    public let duration: String
    public let activeEnergy: String
    public let totalEnergy: String
    public let distance: String?
    public let averageHeartRate: String?
    public let elevationAscended: String?
    public let elevationDescended: String?

    public init(
      name: String,
      start: Date,
      end: Date,
      duration: String,
      activeEnergy: String,
      totalEnergy: String,
      distance: String?,
      averageHeartRate: String?,
      elevationAscended: String?,
      elevationDescended: String?
    ) {
      self.name = name
      self.start = start
      self.end = end
      self.duration = duration
      self.activeEnergy = activeEnergy
      self.totalEnergy = totalEnergy
      self.distance = distance
      self.averageHeartRate = averageHeartRate
      self.elevationAscended = elevationAscended
      self.elevationDescended = elevationDescended
    }
  }

  public struct Workouts: SendableNetworkModel {
    public let workouts: [Workout]
    public let bioAgeSummary: BioAgeSummary?

    public init(workouts: [Workout], bioAgeSummary: BioAgeSummary? = nil) {
      self.workouts = workouts
      self.bioAgeSummary = bioAgeSummary
    }
  }
}

// MARK: - Biological Age

extension HealthVitalData {
  public struct BioAgeContribution: SendableNetworkModel {
    public let metric: String
    public let category: String
    public let value: String
    public let ageDelta: String
    public let impact: String

    public init(metric: String, category: String, value: String, ageDelta: String, impact: String) {
      self.metric = metric
      self.category = category
      self.value = value
      self.ageDelta = ageDelta
      self.impact = impact
    }
  }

  public struct BioAgeSummary: SendableNetworkModel {
    public let biologicalAge: Double
    public let actualAge: Double
    public let ageDelta: Double
    public let confidence: String
    public let lastCalculated: String
    public let relevantContributions: [BioAgeContribution]

    public init(
      biologicalAge: Double,
      actualAge: Double,
      ageDelta: Double,
      confidence: String,
      lastCalculated: String,
      relevantContributions: [BioAgeContribution]
    ) {
      self.biologicalAge = biologicalAge
      self.actualAge = actualAge
      self.ageDelta = ageDelta
      self.confidence = confidence
      self.lastCalculated = lastCalculated
      self.relevantContributions = relevantContributions
    }
  }
}
