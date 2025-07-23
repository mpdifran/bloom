//
//  DayVitalsCalculator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import DataContainer
import BloomFoundation
import HealthKit
import CoreHealth

final actor DayVitalsCalculator {
  static let shared = DayVitalsCalculator()
  
  private let foodLogModelActor = FoodItemLogModelActor.standard()
  private let bowelMovementModelActor = BowelMovementModelActor.standard()
  
  private init() { }
}

extension DayVitalsCalculator {
  
  func calculateVitalsString(for date: Date) async throws -> String {
    let vitalsData = await calculateVitals(for: date)
    let jsonData = try JSONEncoder.bloomModel.encode(vitalsData)
    return String(data: jsonData, encoding: .utf8) ?? "{}"
  }
  
  func calculateVitals(for date: Date) async -> DayVitalsData {
    async let activity = generateActivityData(for: date)
    async let bodyComposition = generateBodyCompositionData(for: date)
    async let heartHealth = generateHeartHealthData(for: date)
    async let nutrition = generateNutritionData(for: date)
    async let sleep = generateSleepData(for: date)
    async let stress = generateStressData(for: date)
    async let exercise = generateExerciseData(for: date)
    
    let (activityResult, bodyCompositionResult, heartHealthResult, nutritionResult, sleepResult, stressResult, exerciseResult) = await (
      activity,
      bodyComposition,
      heartHealth,
      nutrition,
      sleep,
      stress,
      exercise
    )
    
    return DayVitalsData(
      date: date,
      activity: activityResult,
      bodyComposition: bodyCompositionResult,
      heartHealth: heartHealthResult,
      nutrition: nutritionResult,
      sleep: sleepResult,
      stress: stressResult,
      exercise: exerciseResult
    )
  }
}

// MARK: - Activity Data
private extension DayVitalsCalculator {
  
  func generateActivityData(for date: Date) async -> ActivityData? {
    let dateRange = DateRange.duringDay(date)
    
    async let basalEnergy = HealthStoreFetcher.shared.fetchTotalQuantity(for: .basalEnergyBurned, dateRange: dateRange)
    async let activeEnergy = HealthStoreFetcher.shared.fetchTotalQuantity(for: .activeEnergyBurned, dateRange: dateRange)
    async let steps = HealthStoreFetcher.shared.fetchTotalQuantity(for: .stepCount, dateRange: dateRange)
    async let walkingDistance = HealthStoreFetcher.shared.fetchTotalQuantity(for: .distanceWalkingRunning, dateRange: dateRange)
    async let timeInDaylight = HealthStoreFetcher.shared.fetchTotalQuantity(for: .timeInDaylight, dateRange: dateRange)
    
    let (basalResult, activeResult, stepsResult, walkingResult, daylightResult) = await (
      basalEnergy,
      activeEnergy,
      steps,
      walkingDistance,
      timeInDaylight
    )
    
    guard let basal = basalResult, let active = activeResult else { return nil }
    
    let totalEnergy = basal.sum(active, unit: .largeCalorie())
    
    return ActivityData(
      basalEnergyBurned: await basal.displayString(for: .largeCalorie(), formatter: .noDecimalPlaces),
      activeEnergyBurned: await active.displayString(for: .largeCalorie(), formatter: .noDecimalPlaces),
      totalEnergyBurned: await totalEnergy.displayString(for: .largeCalorie(), formatter: .noDecimalPlaces),
      steps: await stepsResult?.displayString(for: .count(), formatter: .noDecimalPlaces),
      walkingDistance: await walkingResult?.displayString(for: .mile(), formatter: .oneDecimalPlace),
      timeInDaylight: await daylightResult?.displayString(for: .minute(), formatter: .noDecimalPlaces)
    )
  }
}

// MARK: - Body Composition Data
private extension DayVitalsCalculator {
  
  func generateBodyCompositionData(for date: Date) async -> BodyCompositionData? {
    let dateRange = DateRange.duringDay(date)
    
    // Fetch daily values
    let bodyMassQuantity = await HealthStoreFetcher.shared.fetchMostRecentSample(for: .bodyMass, dateRange: dateRange)?.quantity
    let bodyFatQuantity = await HealthStoreFetcher.shared.fetchMostRecentSample(for: .bodyFatPercentage, dateRange: dateRange)?.quantity
    let leanBodyMassQuantity = await HealthStoreFetcher.shared.fetchMostRecentSample(for: .leanBodyMass, dateRange: dateRange)?.quantity
    
    // Fetch averages from the vitals (using the core VitalsCalculator)
    let bodyCompositionSummary = await VitalsCalculator.shared.bodyCompositionSummary

    guard bodyMassQuantity != nil || bodyFatQuantity != nil || leanBodyMassQuantity != nil || bodyCompositionSummary != nil else {
      return nil
    }
    
    let bodyMassUnit = await HKUnit.gramUnit(with: .kilo).localizedUnit()
    
    return BodyCompositionData(
      bodyMass: await bodyMassQuantity?.displayString(for: bodyMassUnit, formatter: .oneDecimalPlace),
      bodyMassAverage: await bodyCompositionSummary?.details.averageBodyMass?.displayString(for: bodyMassUnit, formatter: .oneDecimalPlace),
      bodyFatPercentage: await bodyFatQuantity?.displayString(for: .percent(), formatter: .noDecimalPlaces),
      bodyFatPercentageAverage: await bodyCompositionSummary?.details.bodyFatPercentage?.displayString(for: .percent(), formatter: .noDecimalPlaces),
      leanBodyMass: await leanBodyMassQuantity?.displayString(for: bodyMassUnit, formatter: .oneDecimalPlace),
      leanBodyMassAverage: nil // Lean body mass average not available in summary
    )
  }
}

// MARK: - Heart Health Data
private extension DayVitalsCalculator {
  
  func generateHeartHealthData(for date: Date) async -> HeartHealthData? {
    let dateRange = DateRange.duringDay(date)
    
    async let vo2Max = HealthStoreFetcher.shared.fetchMostRecentSample(for: .vo2Max, dateRange: dateRange)?.quantity
    async let rhr = HealthStoreFetcher.shared.fetchMostRecentSample(for: .restingHeartRate, dateRange: dateRange)?.quantity
    async let hrRecovery = HealthStoreFetcher.shared.fetchMostRecentSample(for: .heartRateRecoveryOneMinute, dateRange: dateRange)?.quantity
    async let hrv = HealthStoreFetcher.shared.fetchMostRecentSample(for: .heartRateVariabilitySDNN, dateRange: dateRange)?.quantity
    
    let (vo2Result, rhrResult, recoveryResult, hrvResult) = await (
      vo2Max,
      rhr,
      hrRecovery,
      hrv
    )
    
    guard vo2Result != nil || rhrResult != nil || recoveryResult != nil || hrvResult != nil else {
      return nil
    }
    
    return HeartHealthData(
      vo2Max: await vo2Result?.displayString(for: .vo2Max(), formatter: .noDecimalPlaces),
      restingHeartRate: await rhrResult?.displayString(for: .bpm(), formatter: .noDecimalPlaces),
      heartRateRecovery: await recoveryResult?.displayString(for: .bpm(), formatter: .noDecimalPlaces),
      heartRateVariability: await hrvResult?.displayString(for: .secondUnit(with: .milli), formatter: .noDecimalPlaces)
    )
  }
}

// MARK: - Nutrition Data
private extension DayVitalsCalculator {
  
  func generateNutritionData(for date: Date) async -> NutritionData? {
    let dateRange = DateRange.duringDay(date)
    
    // Fetch macronutrients
    async let calories = HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryEnergyConsumed, dateRange: dateRange)
    async let protein = HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryProtein, dateRange: dateRange)
    async let carbs = HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryCarbohydrates, dateRange: dateRange)
    async let fat = HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryFatTotal, dateRange: dateRange)
    async let saturatedFat = HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryFatSaturated, dateRange: dateRange)
    async let fiber = HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryFiber, dateRange: dateRange)
    async let sugar = HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietarySugar, dateRange: dateRange)
    async let sodium = HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietarySodium, dateRange: dateRange)
    async let water = HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryWater, dateRange: dateRange)
    
    let (caloriesResult, proteinResult, carbsResult, fatResult, saturatedFatResult, fiberResult, sugarResult, sodiumResult, waterResult) = await (
      calories,
      protein,
      carbs,
      fat,
      saturatedFat,
      fiber,
      sugar,
      sodium,
      water
    )
    
    // Fetch meal data
    let meals = await fetchMealData(for: date)
    
    guard caloriesResult != nil || meals.isNotEmpty else { return nil }
    
    return NutritionData(
      totalCalories: await caloriesResult?.displayString(for: .largeCalorie(), formatter: .noDecimalPlaces) ?? "0 cal",
      protein: await proteinResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      carbohydrates: await carbsResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      fat: await fatResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      saturatedFat: await saturatedFatResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      fiber: await fiberResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      sugar: await sugarResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      sodium: await sodiumResult?.displayString(for: .gramUnit(with: .milli), formatter: .noDecimalPlaces),
      water: await waterResult?.displayString(for: .literUnit(with: .milli), formatter: .noDecimalPlaces),
      meals: meals
    )
  }
  
  func fetchMealData(for date: Date) async -> [MealData] {
    do {
      let foodLogs = try await foodLogModelActor.fetchLogs(for: date)
      
      var mealMap: [FoodItemLog.Meal: (items: [FoodItemData], calories: Double)] = [:]
      
      for foodLog in foodLogs {
        for serving in foodLog.foodItemServings {
          guard let foodItem = serving.foodItem else { continue }
          
          let foodItemData = FoodItemData(foodItemLog: foodLog, foodItem: foodItem)
          let calories = foodLog.totalNutrient(foodItem: foodItem, keyPath: \.calories)
          
          if mealMap[foodLog.meal] != nil {
            mealMap[foodLog.meal]?.items.append(foodItemData)
            mealMap[foodLog.meal]?.calories += calories
          } else {
            mealMap[foodLog.meal] = (items: [foodItemData], calories: calories)
          }
        }
      }
      
      return mealMap.map { (meal, data) in
        MealData(
          mealType: meal.name,
          foodItems: data.items,
          totalCalories: "\(Int(data.calories)) cal"
        )
      }.sorted { meal1, meal2 in
        let mealOrder = ["Breakfast", "Lunch", "Dinner", "Snack"]
        let index1 = mealOrder.firstIndex(of: meal1.mealType) ?? Int.max
        let index2 = mealOrder.firstIndex(of: meal2.mealType) ?? Int.max
        return index1 < index2
      }
    } catch {
      return []
    }
  }
}

// MARK: - Sleep Data
private extension DayVitalsCalculator {
  
  func generateSleepData(for date: Date) async -> SleepData? {
    // Sleep data is for the night before the given date
    guard let sleepEndDate = Calendar.current.date(byAdding: .hour, value: 12, to: date),
          let sleepStartDate = Calendar.current.date(byAdding: .hour, value: -12, to: date) else {
      return nil
    }
    
    let sleepDateRange = DateRange(sleepStartDate, sleepEndDate)
    let sleepAnalyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: sleepDateRange)
    
    guard sleepAnalyses.isNotEmpty else { return nil }
    
    var sleepSessions: [SleepSession] = []
    
    for sleepAnalysis in sleepAnalyses {
      let totalSleepQuantity = HKQuantity(unit: .minute(), doubleValue: sleepAnalysis.overallMinutes)
      let totalSleepTime = await totalSleepQuantity.displayString(for: .hour(), formatter: .oneDecimalPlace)
      
      let deepSleepString = sleepAnalysis.hasDetailedSleepCategories ? await HKQuantity(unit: .minute(), doubleValue: sleepAnalysis.deepSleepMinutes).displayString(for: .minute(), formatter: .noDecimalPlaces) : nil
      let coreSleepString = sleepAnalysis.hasDetailedSleepCategories ? await HKQuantity(unit: .minute(), doubleValue: sleepAnalysis.coreSleepMinutes).displayString(for: .minute(), formatter: .noDecimalPlaces) : nil
      let remSleepString = sleepAnalysis.hasDetailedSleepCategories ? await HKQuantity(unit: .minute(), doubleValue: sleepAnalysis.remSleepMinutes).displayString(for: .minute(), formatter: .noDecimalPlaces) : nil
      let awakeTimeString = sleepAnalysis.hasDetailedSleepCategories ? await HKQuantity(unit: .minute(), doubleValue: sleepAnalysis.awakeSleepMinutes).displayString(for: .minute(), formatter: .noDecimalPlaces) : nil
      
      let heartRateString = sleepAnalysis.averageHeartRate.map { "\(Int($0)) bpm" }
      let respiratoryRateString = sleepAnalysis.respiratoryRate.average(keyPath: \.averageRespiratoryRate) > 0 ? "\(Int(sleepAnalysis.respiratoryRate.average(keyPath: \.averageRespiratoryRate))) breaths/min" : nil
      let soundLevelString = sleepAnalysis.averageSoundLevel > 0 ? "\(Int(sleepAnalysis.averageSoundLevel)) dB" : nil
      
      let wristTemperatureString: String?
      if let wristTemp = sleepAnalysis.wristTemperature?.averageWristTemperature {
        let tempQuantity = HKQuantity(unit: .degreeFahrenheit(), doubleValue: wristTemp)
        wristTemperatureString = await tempQuantity.displayString(for: .degreeFahrenheit(), formatter: .oneDecimalPlace)
      } else {
        wristTemperatureString = nil
      }
      
      let sleepSession = SleepSession(
        startDate: sleepAnalysis.startDate,
        endDate: sleepAnalysis.endDate,
        totalSleepTime: totalSleepTime,
        deepSleep: deepSleepString,
        coreSleep: coreSleepString,
        remSleep: remSleepString,
        awakeTime: awakeTimeString,
        averageHeartRate: heartRateString,
        averageRespiratoryRate: respiratoryRateString,
        averageSoundLevel: soundLevelString,
        wristTemperature: wristTemperatureString
      )
      
      sleepSessions.append(sleepSession)
    }
    
    return SleepData(sleepSessions: sleepSessions)
  }
}

// MARK: - Stress Data
private extension DayVitalsCalculator {
  
  func generateStressData(for date: Date) async -> StressData? {
    let dateRange = DateRange.duringDay(date)
    
    let hrvQuantity = await HealthStoreFetcher.shared.fetchMostRecentSample(
      for: .heartRateVariabilitySDNN,
      dateRange: dateRange
    )?.quantity
    
    let systolicQuantity = await HealthStoreFetcher.shared.fetchMostRecentSample(
      for: .bloodPressureSystolic,
      dateRange: dateRange
    )?.quantity
    let diastolicQuantity = await HealthStoreFetcher.shared.fetchMostRecentSample(
      for: .bloodPressureDiastolic,
      dateRange: dateRange
    )?.quantity
    
    let bloodPressure: BloodPressureData?
    if let systolic = systolicQuantity, let diastolic = diastolicQuantity {
      bloodPressure = BloodPressureData(
        systolic: await systolic.displayString(for: .millimeterOfMercury(), formatter: .noDecimalPlaces, showUnits: false),
        diastolic: await diastolic.displayString(for: .millimeterOfMercury(), formatter: .noDecimalPlaces, showUnits: false),
        date: date
      )
    } else {
      bloodPressure = nil
    }
    
    guard hrvQuantity != nil || bloodPressure != nil else { return nil }
    
    return StressData(
      heartRateVariability: await hrvQuantity?.displayString(for: .secondUnit(with: .milli), formatter: .noDecimalPlaces),
      bloodPressure: bloodPressure
    )
  }
}

// MARK: - Exercise Data
private extension DayVitalsCalculator {
  
  func generateExerciseData(for date: Date) async -> ExerciseData? {
    let dateRange = DateRange.duringDay(date)
    
    let workouts = await HealthStoreFetcher.shared.fetchWorkouts(dateRange: dateRange)
    guard workouts.isNotEmpty else { return nil }
    
    var workoutData = [WorkoutData]()
    var totalMinutes: Double = 0
    var totalCalories: Double = 0
    
    for workout in workouts {
      let duration = workout.duration / 60 // Convert to minutes
      totalMinutes += duration
      
      let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .largeCalorie()) ?? 0
      totalCalories += calories
      
      let heartRateReports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let workoutReport = heartRateReports.first { $0.workout.uuid == workout.uuid }
      
      let heartRateZones: HeartRateZoneData?
      if let report = workoutReport {
        heartRateZones = HeartRateZoneData(
          zone1Minutes: await report.heartZoneDistribution.zone1.displayString(for: .minute(), formatter: .noDecimalPlaces),
          zone2Minutes: await report.heartZoneDistribution.zone2.displayString(for: .minute(), formatter: .noDecimalPlaces),
          zone3Minutes: await report.heartZoneDistribution.zone3.displayString(for: .minute(), formatter: .noDecimalPlaces),
          zone4Minutes: await report.heartZoneDistribution.zone4.displayString(for: .minute(), formatter: .noDecimalPlaces),
          zone5Minutes: await report.heartZoneDistribution.zone5.displayString(for: .minute(), formatter: .noDecimalPlaces)
        )
      } else {
        heartRateZones = nil
      }
      
      let workoutDataItem = WorkoutData(
        activityType: workout.workoutActivityType.name,
        startTime: workout.startDate,
        duration: await HKQuantity(unit: .minute(), doubleValue: duration).displayString(for: .minute(), formatter: .noDecimalPlaces),
        caloriesBurned: "\(Int(calories)) cal",
        distance: await workout.totalDistance?.displayString(for: .mile(), formatter: .oneDecimalPlace),
        averageHeartRate: workoutReport?.averageHeartRate.map { "\(Int($0)) bpm" },
        heartRateZones: heartRateZones
      )
      
      workoutData.append(workoutDataItem)
    }
    
    return ExerciseData(
      workouts: workoutData,
      totalExerciseMinutes: await HKQuantity(unit: .minute(), doubleValue: totalMinutes).displayString(for: .minute(), formatter: .noDecimalPlaces),
      totalCaloriesBurned: "\(Int(totalCalories)) cal"
    )
  }
}
