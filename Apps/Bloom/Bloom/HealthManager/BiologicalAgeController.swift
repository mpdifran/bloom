//
//  BiologicalAgeController.swift
//  Bloom
//
//  Created by Assistant on 2025-09-15.
//

import Foundation
import HealthKit
import DataContainer
import CoreHealth
import BloomFoundation
import SwiftData

@Observable
@MainActor
final class BiologicalAgeController {
  
  private let healthStoreFetcher = HealthStoreFetcher.shared
  private let modelContext: ModelContext
  
  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }
  
  func collectBiologicalAgeData() async throws -> BiologicalAgeHealthData {
    let dateRange = DateRange.trailingDaysFromNow(7)
    
    async let cardiovascular = fetchCardiovascularHealth(dateRange: dateRange)
    async let sleep = fetchSleepMetrics(dateRange: dateRange)
    async let activity = fetchActivityMetrics(dateRange: dateRange)
    async let nutrition = fetchNutritionMetrics(dateRange: dateRange)
    async let body = fetchBodyMetrics()
    async let recovery = fetchRecoveryIndicators(dateRange: dateRange)
    async let sex = fetchBiologicalSex()
    
    return BiologicalAgeHealthData(
      sevenDayAverage: BiologicalAgeHealthData.SevenDayAverage(
        cardiovascular: await cardiovascular,
        sleep: await sleep,
        activity: await activity,
        nutrition: await nutrition,
        bodyComposition: await body,
        recovery: await recovery
      ),
      biologicalSex: await sex
    )
  }
  
  private func fetchCardiovascularHealth(dateRange: DateRange) async -> BiologicalAgeHealthData.CardiovascularHealth? {
    async let restingHR = fetchRestingHeartRate(dateRange: dateRange)
    async let hrv = fetchHeartRateVariability(dateRange: dateRange)
    async let vo2Max = fetchVO2Max()
    async let hrRecovery = fetchHeartRateRecovery(dateRange: dateRange)
    
    let restingHRResult = await restingHR
    let hrvResult = await hrv
    let vo2MaxResult = await vo2Max
    let hrRecoveryResult = await hrRecovery
    
    guard restingHRResult != nil || hrvResult != nil || vo2MaxResult != nil || hrRecoveryResult != nil else {
      return nil
    }
    
    return BiologicalAgeHealthData.CardiovascularHealth(
      averageRestingHeartRate: restingHRResult,
      averageHeartRateVariability: hrvResult,
      averageVO2Max: vo2MaxResult,
      averageHeartRateRecovery: hrRecoveryResult
    )
  }
  
  private func fetchRestingHeartRate(dateRange: DateRange) async -> BiologicalAgeHealthData.CardiovascularHealth.HeartRateMetric? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.restingHeartRate),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    guard !samples.isEmpty else { return nil }
    
    let values = samples.map { $0.quantity.doubleValue(for: .bpm()) }
    let average = values.reduce(0, +) / Double(values.count)
    let min = values.min() ?? 0
    let max = values.max() ?? 0
    
    let previousWeekRange = DateRange.previousWeek(from: dateRange)
    let previousSamples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.restingHeartRate),
      dateRange: previousWeekRange
    ).compactMap { $0 as? HKQuantitySample }
    
    let trend = calculateTrend(current: average, previous: previousSamples, unit: .bpm(), lowerIsBetter: true)
    
    return BiologicalAgeHealthData.CardiovascularHealth.HeartRateMetric(
      average: HKQuantity(unit: .bpm(), doubleValue: average).displayString(for: .bpm()),
      min: HKQuantity(unit: .bpm(), doubleValue: min).displayString(for: .bpm()),
      max: HKQuantity(unit: .bpm(), doubleValue: max).displayString(for: .bpm()),
      trend: trend
    )
  }
  
  private func fetchHeartRateVariability(dateRange: DateRange) async -> BiologicalAgeHealthData.CardiovascularHealth.HRVMetric? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.heartRateVariabilitySDNN),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    guard !samples.isEmpty else { return nil }
    
    let values = samples.map { $0.quantity.doubleValue(for: .secondUnit(with: .milli)) }
    let average = values.reduce(0, +) / Double(values.count)
    
    let previousWeekRange = DateRange.previousWeek(from: dateRange)
    let previousSamples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.heartRateVariabilitySDNN),
      dateRange: previousWeekRange
    ).compactMap { $0 as? HKQuantitySample }
    
    let trend = calculateTrend(current: average, previous: previousSamples, unit: .secondUnit(with: .milli), lowerIsBetter: false)
    
    let unit = HKUnit.secondUnit(with: .milli)
    return BiologicalAgeHealthData.CardiovascularHealth.HRVMetric(
      average: HKQuantity(unit: unit, doubleValue: average).displayString(for: unit),
      trend: trend
    )
  }
  
  private func fetchVO2Max() async -> BiologicalAgeHealthData.MetricValue? {
    let dateRange = DateRange.trailingDaysFromNow(30)
    
    guard let sample = await healthStoreFetcher.fetchMostRecentSample(
      for: .vo2Max,
      dateRange: dateRange
    ) else { return nil }
    
    let value = sample.quantity.doubleValue(for: .literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute()))
    
    // Fetch previous period for trend calculation
    let previousDateRange = DateRange.previousPeriod(from: dateRange, days: 30)
    
    let previousSamples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.vo2Max),
      dateRange: previousDateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    let unit = HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute())
    let trend = calculateTrend(current: value, previous: previousSamples, unit: unit, lowerIsBetter: false)
    
    return BiologicalAgeHealthData.MetricValue(
      value: HKQuantity(unit: unit, doubleValue: value).displayString(for: unit),
      trend: trend
    )
  }
  
  private func fetchHeartRateRecovery(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.heartRateRecoveryOneMinute),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    guard !samples.isEmpty else { return nil }
    
    let values = samples.map { $0.quantity.doubleValue(for: .bpm()) }
    let average = values.reduce(0, +) / Double(values.count)
    
    // Fetch previous week for trend calculation
    let previousWeekRange = DateRange.previousWeek(from: dateRange)
    let previousSamples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.heartRateRecoveryOneMinute),
      dateRange: previousWeekRange
    ).compactMap { $0 as? HKQuantitySample }
    
    let trend = calculateTrend(current: average, previous: previousSamples, unit: .bpm(), lowerIsBetter: false)
    
    return BiologicalAgeHealthData.MetricValue(
      value: HKQuantity(unit: .bpm(), doubleValue: average).displayString(for: .bpm()),
      trend: trend
    )
  }
  
  private func fetchSleepMetrics(dateRange: DateRange) async -> BiologicalAgeHealthData.SleepMetrics? {
    let sleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(dateRange: dateRange)
    
    guard !sleepAnalyses.isEmpty else { return nil }
    
    // Fetch previous week data for trend calculations
    let previousWeekRange = DateRange.previousWeek(from: dateRange)
    let previousSleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(dateRange: previousWeekRange)
    
    let durations = sleepAnalyses.map { $0.overallMinutes }
    let averageDuration = durations.reduce(0, +) / Double(durations.count)
    
    let efficiencies = sleepAnalyses.compactMap { analysis -> Double? in
      guard analysis.overallMinutesIncludingAwake > 0 else { return nil }
      return (analysis.overallMinutes / analysis.overallMinutesIncludingAwake) * 100
    }
    let averageEfficiency = efficiencies.isEmpty ? nil : efficiencies.reduce(0, +) / Double(efficiencies.count)
    
    let deepSleepMinutes = sleepAnalyses.map { $0.deepSleepMinutes }
    let averageDeepMinutes = deepSleepMinutes.isEmpty ? nil : deepSleepMinutes.reduce(0, +) / Double(deepSleepMinutes.count)
    
    let remSleepMinutes = sleepAnalyses.map { $0.remSleepMinutes }
    let averageRemMinutes = remSleepMinutes.isEmpty ? nil : remSleepMinutes.reduce(0, +) / Double(remSleepMinutes.count)
    
    let wakeMinutes = sleepAnalyses.map { $0.awakeSleepMinutes }
    let averageWakeMinutes = wakeMinutes.isEmpty ? nil : wakeMinutes.reduce(0, +) / Double(wakeMinutes.count)
    
    let deepSleepPercentage: Double? = {
      guard let deepMinutes = averageDeepMinutes, averageDuration > 0 else { return nil }
      return (deepMinutes / averageDuration) * 100
    }()
    
    let remSleepPercentage: Double? = {
      guard let remMinutes = averageRemMinutes, averageDuration > 0 else { return nil }
      return (remMinutes / averageDuration) * 100
    }()
    
    // Calculate trends
    let durationTrend = calculateSleepTrend(
      current: averageDuration,
      previous: previousSleepAnalyses.map { $0.overallMinutes },
      lowerIsBetter: false
    )
    
    let efficiencyTrend: BiologicalAgeHealthData.MetricValue.Trend? = {
      guard let currentEfficiency = averageEfficiency else { return nil }
      let previousEfficiencies = previousSleepAnalyses.compactMap { analysis -> Double? in
        guard analysis.overallMinutesIncludingAwake > 0 else { return nil }
        return (analysis.overallMinutes / analysis.overallMinutesIncludingAwake) * 100
      }
      return calculateSleepTrend(current: currentEfficiency, previous: previousEfficiencies, lowerIsBetter: false)
    }()
    
    let deepSleepTrend: BiologicalAgeHealthData.MetricValue.Trend? = {
      guard let currentDeep = averageDeepMinutes else { return nil }
      return calculateSleepTrend(current: currentDeep, previous: previousSleepAnalyses.map { $0.deepSleepMinutes }, lowerIsBetter: false)
    }()
    
    let remSleepTrend: BiologicalAgeHealthData.MetricValue.Trend? = {
      guard let currentRem = averageRemMinutes else { return nil }
      return calculateSleepTrend(current: currentRem, previous: previousSleepAnalyses.map { $0.remSleepMinutes }, lowerIsBetter: false)
    }()
    
    let wakeTrend: BiologicalAgeHealthData.MetricValue.Trend? = {
      guard let currentWake = averageWakeMinutes else { return nil }
      return calculateSleepTrend(current: currentWake, previous: previousSleepAnalyses.map { $0.awakeSleepMinutes }, lowerIsBetter: true)
    }()
    
    return BiologicalAgeHealthData.SleepMetrics(
      averageSleepDuration: BiologicalAgeHealthData.MetricValue(
        value: HKQuantity(unit: .hour(), doubleValue: averageDuration / 60).displayString(for: .hour()),
        trend: durationTrend
      ),
      averageSleepEfficiency: averageEfficiency.map { 
        BiologicalAgeHealthData.MetricValue(value: String(format: "%.1f%%", $0), trend: efficiencyTrend)
      },
      averageDeepSleep: averageDeepMinutes.map { minutes in
        BiologicalAgeHealthData.SleepMetrics.SleepStageMetric(
          averageMinutes: HKQuantity(unit: .minute(), doubleValue: minutes).displayString(for: .minute()),
          averagePercentage: String(format: "%.1f%%", deepSleepPercentage ?? 0),
          trend: deepSleepTrend
        )
      },
      averageRemSleep: averageRemMinutes.map { minutes in
        BiologicalAgeHealthData.SleepMetrics.SleepStageMetric(
          averageMinutes: HKQuantity(unit: .minute(), doubleValue: minutes).displayString(for: .minute()),
          averagePercentage: String(format: "%.1f%%", remSleepPercentage ?? 0),
          trend: remSleepTrend
        )
      },
      averageWakeMinutes: averageWakeMinutes.map {
        BiologicalAgeHealthData.MetricValue(value: HKQuantity(unit: .minute(), doubleValue: $0).displayString(for: .minute()), trend: wakeTrend)
      }
    )
  }
  
  private func fetchActivityMetrics(dateRange: DateRange) async -> BiologicalAgeHealthData.ActivityMetrics? {
    async let steps = fetchDailySteps(dateRange: dateRange)
    async let activeEnergy = fetchActiveEnergy(dateRange: dateRange)
    async let exerciseMinutes = fetchExerciseMinutes(dateRange: dateRange)
    async let workouts = fetchWorkoutCount(dateRange: dateRange)
    async let walkingSpeed = fetchWalkingSpeed(dateRange: dateRange)
    
    let stepsResult = await steps
    let activeEnergyResult = await activeEnergy
    let exerciseMinutesResult = await exerciseMinutes
    let workoutsResult = await workouts
    let walkingSpeedResult = await walkingSpeed
    
    guard stepsResult != nil || activeEnergyResult != nil || exerciseMinutesResult != nil || workoutsResult != nil || walkingSpeedResult != nil else {
      return nil
    }
    
    return BiologicalAgeHealthData.ActivityMetrics(
      averageDailySteps: stepsResult,
      averageActiveEnergy: activeEnergyResult,
      totalExerciseMinutes: exerciseMinutesResult,
      totalWorkoutCount: workoutsResult,
      averageWalkingSpeed: walkingSpeedResult
    )
  }
  
  private func fetchDailySteps(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .stepCount,
      unit: .count(),
      dateRange: dateRange
    )
    
    guard !samples.isEmpty else { return nil }
    
    let dailySteps = samples.map { $0.quantity.doubleValue(for: .count()) }
    let averageSteps = dailySteps.reduce(0, +) / Double(dailySteps.count)
    
    // Fetch previous week for trend calculation
    let previousWeekRange = DateRange.previousWeek(from: dateRange)
    let previousSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .stepCount,
      unit: .count(),
      dateRange: previousWeekRange
    )
    
    let previousSteps = previousSamples.map { $0.quantity.doubleValue(for: .count()) }
    let previousAverageSteps = previousSteps.isEmpty ? 0 : previousSteps.reduce(0, +) / Double(previousSteps.count)
    let trend = calculateSleepTrend(current: averageSteps, previous: [previousAverageSteps], lowerIsBetter: false)
    
    return BiologicalAgeHealthData.MetricValue(
      value: HKQuantity(unit: .count(), doubleValue: averageSteps).displayString(for: .count()),
      trend: trend
    )
  }
  
  private func fetchActiveEnergy(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .activeEnergyBurned,
      unit: .kilocalorie(),
      dateRange: dateRange
    )
    
    guard !samples.isEmpty else { return nil }
    
    let dailyCalories = samples.map { $0.quantity.doubleValue(for: .kilocalorie()) }
    let averageCalories = dailyCalories.reduce(0, +) / Double(dailyCalories.count)
    
    // Fetch previous week for trend calculation
    let previousWeekRange = DateRange.previousWeek(from: dateRange)
    let previousSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .activeEnergyBurned,
      unit: .kilocalorie(),
      dateRange: previousWeekRange
    )
    
    let previousCalories = previousSamples.map { $0.quantity.doubleValue(for: .kilocalorie()) }
    let previousAverageCalories = previousCalories.isEmpty ? 0 : previousCalories.reduce(0, +) / Double(previousCalories.count)
    let trend = calculateSleepTrend(current: averageCalories, previous: [previousAverageCalories], lowerIsBetter: false)
    
    return BiologicalAgeHealthData.MetricValue(
      value: HKQuantity(unit: .kilocalorie(), doubleValue: averageCalories).displayString(for: .kilocalorie()),
      trend: trend
    )
  }
  
  private func fetchExerciseMinutes(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .appleExerciseTime,
      unit: .minute(),
      dateRange: dateRange
    )
    
    guard !samples.isEmpty else { return nil }
    
    let dailyMinutes = samples.map { $0.quantity.doubleValue(for: .minute()) }
    let totalMinutes = dailyMinutes.reduce(0, +)
    
    // Fetch previous week for trend calculation
    let previousWeekRange = DateRange.previousWeek(from: dateRange)
    let previousSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .appleExerciseTime,
      unit: .minute(),
      dateRange: previousWeekRange
    )
    
    let previousTotalMinutes = previousSamples.map { $0.quantity.doubleValue(for: .minute()) }.reduce(0, +)
    let trend = calculateSleepTrend(current: totalMinutes, previous: [previousTotalMinutes], lowerIsBetter: false)
    
    return BiologicalAgeHealthData.MetricValue(
      value: HKQuantity(unit: .minute(), doubleValue: totalMinutes).displayString(for: .minute()),
      trend: trend
    )
  }
  
  private func fetchWorkoutCount(dateRange: DateRange) async -> Int? {
    let workouts = await healthStoreFetcher.fetchWorkouts(dateRange: dateRange)
    return workouts.isEmpty ? nil : workouts.count
  }
  
  private func fetchWalkingSpeed(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.walkingSpeed),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    guard !samples.isEmpty else { return nil }
    
    let speeds = samples.map { $0.quantity.doubleValue(for: .meter().unitDivided(by: .second())) }
    let averageSpeed = speeds.reduce(0, +) / Double(speeds.count)
    
    // Fetch previous week for trend calculation
    let previousWeekRange = DateRange.previousWeek(from: dateRange)
    let previousSamples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.walkingSpeed),
      dateRange: previousWeekRange
    ).compactMap { $0 as? HKQuantitySample }
    
    let unit = HKUnit.meter().unitDivided(by: .second())
    let trend = calculateTrend(current: averageSpeed, previous: previousSamples, unit: unit, lowerIsBetter: false)
    
    return BiologicalAgeHealthData.MetricValue(
      value: HKQuantity(unit: unit, doubleValue: averageSpeed).displayString(for: unit),
      trend: trend
    )
  }
  
  private func fetchNutritionMetrics(dateRange: DateRange) async -> BiologicalAgeHealthData.NutritionMetrics? {
    async let calories = fetchNutrientAverage(type: .dietaryEnergyConsumed, dateRange: dateRange, unit: .kilocalorie())
    async let protein = fetchNutrientAverage(type: .dietaryProtein, dateRange: dateRange, unit: .gram())
    async let carbs = fetchNutrientAverage(type: .dietaryCarbohydrates, dateRange: dateRange, unit: .gram())
    async let fat = fetchNutrientAverage(type: .dietaryFatTotal, dateRange: dateRange, unit: .gram())
    async let fiber = fetchNutrientAverage(type: .dietaryFiber, dateRange: dateRange, unit: .gram())
    async let sugar = fetchNutrientAverage(type: .dietarySugar, dateRange: dateRange, unit: .gram())
    async let saturatedFat = fetchNutrientAverage(type: .dietaryFatSaturated, dateRange: dateRange, unit: .gram())
    async let dietQuality = fetchDietQuality(dateRange: dateRange)
    
    let caloriesResult = await calories
    let proteinResult = await protein
    let carbsResult = await carbs
    let fatResult = await fat
    let fiberResult = await fiber
    let sugarResult = await sugar
    let saturatedFatResult = await saturatedFat
    let dietQualityResult = await dietQuality
    
    guard caloriesResult != nil || proteinResult != nil || carbsResult != nil || 
          fatResult != nil || fiberResult != nil || sugarResult != nil || 
          saturatedFatResult != nil || dietQualityResult != nil else {
      return nil
    }
    
    return BiologicalAgeHealthData.NutritionMetrics(
      averageCalories: caloriesResult,
      averageProtein: proteinResult,
      averageCarbohydrates: carbsResult,
      averageTotalFat: fatResult,
      averageFiber: fiberResult,
      averageSugar: sugarResult,
      averageSaturatedFat: saturatedFatResult,
      averageDietQuality: dietQualityResult
    )
  }
  
  private func fetchNutrientAverage(
    type: HKQuantityTypeIdentifier,
    dateRange: DateRange,
    unit: HKUnit
  ) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchCollatedQuantity(
      for: type,
      unit: unit,
      dateRange: dateRange
    )
    
    guard !samples.isEmpty else { return nil }
    
    let dailyValues = samples.map { $0.quantity.doubleValue(for: unit) }
    let average = dailyValues.reduce(0, +) / Double(dailyValues.count)
    
    // Fetch previous week for trend calculation
    let previousWeekRange = DateRange.previousWeek(from: dateRange)
    let previousSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: type,
      unit: unit,
      dateRange: previousWeekRange
    )
    
    // Determine if lower is better for this nutrient
    let lowerIsBetter: Bool = {
      switch type {
      case .dietarySugar, .dietaryFatSaturated:
        return true
      default:
        return false
      }
    }()
    
    let previousValues = previousSamples.map { $0.quantity.doubleValue(for: unit) }
    let previousAverage = previousValues.isEmpty ? 0 : previousValues.reduce(0, +) / Double(previousValues.count)
    let trend = calculateSleepTrend(current: average, previous: [previousAverage], lowerIsBetter: lowerIsBetter)
    
    return BiologicalAgeHealthData.MetricValue(
      value: HKQuantity(unit: unit, doubleValue: average).displayString(for: unit),
      trend: trend
    )
  }
  
  private func fetchDietQuality(dateRange: DateRange) async -> BiologicalAgeHealthData.NutritionMetrics.DietQuality? {
    let calendar = Calendar.current
    let days = calendar.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 7
    
    var processedFoodCount = 0
    var totalFoodCount = 0
    var vegetableServings = 0.0
    
    for dayOffset in 0..<days {
      guard let date = calendar.date(byAdding: .day, value: dayOffset, to: dateRange.start) else { continue }
      
      let dayStart = calendar.startOfDay(for: date)
      let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
      
      let predicate = #Predicate<FoodItemLog> { log in
        log.date >= dayStart && log.date < dayEnd
      }
      
      let descriptor = FetchDescriptor<FoodItemLog>(predicate: predicate)
      
      do {
        let foodItemLogs = try modelContext.fetch(descriptor)
        
        for foodItemLog in foodItemLogs {
          if let foodItemServings = foodItemLog.foodItemServings {
            for serving in foodItemServings {
              totalFoodCount += 1
              
              if let ingredients = serving.foodItem?.ingredients,
                 !ingredients.isEmpty {
                let lowercasedIngredients = ingredients.lowercased()
                if containsProcessedIndicators(lowercasedIngredients) {
                  processedFoodCount += 1
                }
              }
              
              if let name = serving.foodItem?.name.lowercased() {
                if isVegetableOrFruit(name) {
                  vegetableServings += serving.numberOfServings
                }
              }
            }
          }
        }
      } catch {
        print("Error fetching food item logs: \(error)")
      }
    }
    
    guard totalFoodCount > 0 else { return nil }
    
    let processedFoodPercentage = Double(processedFoodCount) / Double(totalFoodCount)
    let processedFoodScore: BiologicalAgeHealthData.NutritionMetrics.DietQuality.ProcessedFoodLevel = {
      if processedFoodPercentage < 0.2 {
        return .low
      } else if processedFoodPercentage < 0.5 {
        return .medium
      } else {
        return .high
      }
    }()
    
    let averageVegetableServings = vegetableServings / Double(days)
    
    return BiologicalAgeHealthData.NutritionMetrics.DietQuality(
      processedFoodScore: processedFoodScore,
      vegetableServings: averageVegetableServings > 0 ? averageVegetableServings : nil
    )
  }
  
  private func containsProcessedIndicators(_ ingredients: String) -> Bool {
    let processedIndicators = [
      "artificial", "preservative", "modified", "hydrogenated",
      "corn syrup", "high fructose", "msg", "nitrate", "nitrite",
      "sodium benzoate", "bht", "bha", "tbhq", "aspartame",
      "sucralose", "acesulfame", "food coloring", "red 40", "yellow 5"
    ]
    
    return processedIndicators.contains { ingredients.contains($0) }
  }
  
  private func isVegetableOrFruit(_ name: String) -> Bool {
    let vegetables = [
      "lettuce", "tomato", "cucumber", "carrot", "broccoli", "spinach",
      "kale", "cabbage", "cauliflower", "pepper", "onion", "garlic",
      "celery", "asparagus", "zucchini", "squash", "bean", "pea",
      "corn", "potato", "sweet potato", "mushroom", "eggplant"
    ]
    
    let fruits = [
      "apple", "banana", "orange", "grape", "strawberry", "blueberry",
      "raspberry", "blackberry", "cherry", "peach", "pear", "plum",
      "apricot", "mango", "pineapple", "watermelon", "cantaloupe",
      "honeydew", "kiwi", "pomegranate", "grapefruit", "lemon", "lime"
    ]
    
    return vegetables.contains { name.contains($0) } || fruits.contains { name.contains($0) }
  }
  
  private func fetchBodyMetrics() async -> BiologicalAgeHealthData.BodyMetrics? {
    async let weight = fetchLatestWeight()
    async let bmi = fetchLatestBMI()
    async let bodyFat = fetchLatestBodyFat()
    
    let weightResult = await weight
    let bmiResult = await bmi
    let bodyFatResult = await bodyFat
    
    guard weightResult != nil || bmiResult != nil || bodyFatResult != nil else {
      return nil
    }
    
    return BiologicalAgeHealthData.BodyMetrics(
      averageWeight: weightResult,
      averageBMI: bmiResult,
      averageBodyFatPercentage: bodyFatResult
    )
  }
  
  private func fetchLatestWeight() async -> BiologicalAgeHealthData.MetricValue? {
    let dateRange = DateRange.trailingDaysFromNow(30)
    
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.bodyMass),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    guard !samples.isEmpty else { return nil }
    
    let weights = samples.map { $0.quantity.doubleValue(for: .pound()) }
    let averageWeight = weights.reduce(0, +) / Double(weights.count)
    
    // Fetch previous period for trend calculation
    let previousDateRange = DateRange.previousPeriod(from: dateRange, days: 30)
    
    let previousSamples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.bodyMass),
      dateRange: previousDateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    let trend = calculateTrend(current: averageWeight, previous: previousSamples, unit: .pound(), lowerIsBetter: false)
    
    return BiologicalAgeHealthData.MetricValue(
      value: HKQuantity(unit: .pound(), doubleValue: averageWeight).displayString(for: .pound()),
      trend: trend
    )
  }
  
  private func fetchLatestBMI() async -> BiologicalAgeHealthData.MetricValue? {
    let dateRange = DateRange.trailingDaysFromNow(30)
    
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.bodyMassIndex),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    guard !samples.isEmpty else { return nil }
    
    let bmis = samples.map { $0.quantity.doubleValue(for: .count()) }
    let averageBMI = bmis.reduce(0, +) / Double(bmis.count)
    
    // Fetch previous period for trend calculation
    let previousDateRange = DateRange.previousPeriod(from: dateRange, days: 30)
    
    let previousSamples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.bodyMassIndex),
      dateRange: previousDateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    let trend = calculateTrend(current: averageBMI, previous: previousSamples, unit: .count(), lowerIsBetter: false)
    
    return BiologicalAgeHealthData.MetricValue(
      value: HKQuantity(unit: .count(), doubleValue: averageBMI).displayString(for: .count(), showUnits: false) + " kg/m²",
      trend: trend
    )
  }
  
  private func fetchLatestBodyFat() async -> BiologicalAgeHealthData.MetricValue? {
    let dateRange = DateRange.trailingDaysFromNow(30)
    
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.bodyFatPercentage),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    guard !samples.isEmpty else { return nil }
    
    let bodyFats = samples.map { $0.quantity.doubleValue(for: .percent()) * 100 }
    let averageBodyFat = bodyFats.reduce(0, +) / Double(bodyFats.count)
    
    // Fetch previous period for trend calculation
    let previousDateRange = DateRange.previousPeriod(from: dateRange, days: 30)
    
    let previousSamples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.bodyFatPercentage),
      dateRange: previousDateRange
    ).compactMap { $0 as? HKQuantitySample }
    
    let previousBodyFats = previousSamples.map { $0.quantity.doubleValue(for: .percent()) * 100 }
    let previousAverage = previousBodyFats.isEmpty ? 0 : previousBodyFats.reduce(0, +) / Double(previousBodyFats.count)
    let trend = calculateSleepTrend(current: averageBodyFat, previous: [previousAverage], lowerIsBetter: true)
    
    return BiologicalAgeHealthData.MetricValue(
      value: String(format: "%.1f%%", averageBodyFat),
      trend: trend
    )
  }
  
  private func fetchRecoveryIndicators(dateRange: DateRange) async -> BiologicalAgeHealthData.RecoveryIndicators? {
    let workouts = await healthStoreFetcher.fetchWorkouts(dateRange: dateRange)
    
    let daysSinceLastWorkout: Int? = {
      guard let lastWorkout = workouts.max(by: { $0.endDate < $1.endDate }) else { return nil }
      let days = Calendar.current.dateComponents([.day], from: lastWorkout.endDate, to: Date()).day
      return days
    }()
    
    return BiologicalAgeHealthData.RecoveryIndicators(
      morningRestingHRTrend: nil,
      hrvTrend: nil,
      daysSinceLastWorkout: daysSinceLastWorkout
    )
  }
  
  private func fetchBiologicalSex() async -> String? {
    let healthStore = HKHealthStore()
    
    guard HKHealthStore.isHealthDataAvailable() else { return nil }
    
    do {
      let sex = try healthStore.biologicalSex().biologicalSex
      switch sex {
      case .male:
        return "male"
      case .female:
        return "female"
      default:
        return nil
      }
    } catch {
      return nil
    }
  }
  
  private func calculateTrend(
    current: Double,
    previous: [HKQuantitySample],
    unit: HKUnit,
    lowerIsBetter: Bool
  ) -> BiologicalAgeHealthData.MetricValue.Trend? {
    guard !previous.isEmpty else { return nil }
    
    let previousValues = previous.map { $0.quantity.doubleValue(for: unit) }
    let previousAverage = previousValues.reduce(0, +) / Double(previousValues.count)
    
    let percentChange = ((current - previousAverage) / previousAverage) * 100
    
    if abs(percentChange) < 5 {
      return .stable
    } else {
      return percentChange > 0 ? .increasing : .decreasing
    }
  }
  
  private func calculateSleepTrend(
    current: Double,
    previous: [Double],
    lowerIsBetter: Bool
  ) -> BiologicalAgeHealthData.MetricValue.Trend? {
    guard !previous.isEmpty else { return nil }
    
    let previousAverage = previous.reduce(0, +) / Double(previous.count)
    
    let percentChange = ((current - previousAverage) / previousAverage) * 100
    
    if abs(percentChange) < 5 {
      return .stable
    } else {
      return percentChange > 0 ? .increasing : .decreasing
    }
  }
}
