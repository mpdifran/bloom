//
//  BiologicalAgeHealthContextCalculator.swift
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

actor BiologicalAgeHealthContextCalculator {

  private let healthStoreFetcher = HealthStoreFetcher.shared
  private let modelContext: ModelContext

  init() {
    self.modelContext = ModelContext(ContainerHolder.shared.container)
  }
  
  func collectBiologicalAgeData() async throws -> BiologicalAgeHealthData {
    let dateRange = DateRange.trailingDaysFromNow(7)

    async let cardiovascular = fetchCardiovascularHealth(dateRange: dateRange)
    async let sleep = fetchSleepMetrics(dateRange: dateRange)
    async let activity = fetchActivityMetrics(dateRange: dateRange)
    async let mobility = fetchMobilityMetrics(dateRange: dateRange)
    async let nutrition = fetchNutritionMetrics(dateRange: dateRange)
    async let body = fetchBodyMetrics()
    async let recovery = fetchRecoveryIndicators(dateRange: dateRange)
    async let sex = fetchBiologicalSex()

    return BiologicalAgeHealthData(
      sevenDayAverage: BiologicalAgeHealthData.SevenDayAverage(
        cardiovascular: await cardiovascular,
        sleep: await sleep,
        activity: await activity,
        mobility: await mobility,
        nutrition: await nutrition,
        bodyComposition: await body,
        recovery: await recovery
      ),
      biologicalSex: await sex
    )
  }

  func fetchCurrentAge() async -> Int? {
    return await MainActor.run {
      let healthStore = HKHealthStore()
      return healthStore.age()
    }
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

    return BiologicalAgeHealthData.CardiovascularHealth.HeartRateMetric(
      average: await HKQuantity(unit: .bpm(), doubleValue: average).displayString(for: .bpm()),
      min: await HKQuantity(unit: .bpm(), doubleValue: min).displayString(for: .bpm()),
      max: await HKQuantity(unit: .bpm(), doubleValue: max).displayString(for: .bpm())
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

    let unit = HKUnit.secondUnit(with: .milli)
    return BiologicalAgeHealthData.CardiovascularHealth.HRVMetric(
      average: await HKQuantity(unit: unit, doubleValue: average).displayString(for: unit)
    )
  }
  
  private func fetchVO2Max() async -> BiologicalAgeHealthData.MetricValue? {
    let dateRange = DateRange.trailingDaysFromNow(30)

    guard let sample = await healthStoreFetcher.fetchMostRecentSample(
      for: .vo2Max,
      dateRange: dateRange
    ) else { return nil }

    let value = sample.quantity.doubleValue(for: .literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute()))

    let unit = HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute())

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: unit, doubleValue: value).displayString(for: unit)
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

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: .bpm(), doubleValue: average).displayString(for: .bpm())
    )
  }
  
  private func fetchSleepMetrics(dateRange: DateRange) async -> BiologicalAgeHealthData.SleepMetrics? {
    return await CentralizedSleepCalculator.shared.calculateSleepMetricsForBiologicalAge(dateRange: dateRange)
  }
  
  private func fetchActivityMetrics(dateRange: DateRange) async -> BiologicalAgeHealthData.ActivityMetrics? {
    async let activeEnergy = fetchActiveEnergy(dateRange: dateRange)
    async let exerciseMinutes = fetchExerciseMinutes(dateRange: dateRange)
    async let workouts = fetchWorkoutCount(dateRange: dateRange)

    let activeEnergyResult = await activeEnergy
    let exerciseMinutesResult = await exerciseMinutes
    let workoutsResult = await workouts

    guard activeEnergyResult != nil || exerciseMinutesResult != nil || workoutsResult != nil else {
      return nil
    }

    return BiologicalAgeHealthData.ActivityMetrics(
      averageActiveEnergy: activeEnergyResult,
      totalExerciseMinutes: exerciseMinutesResult,
      totalWorkoutCount: workoutsResult
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

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: .kilocalorie(), doubleValue: averageCalories).displayString(for: .kilocalorie())
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

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: .minute(), doubleValue: totalMinutes).displayString(for: .minute())
    )
  }
  
  private func fetchWorkoutCount(dateRange: DateRange) async -> Int? {
    let workouts = await healthStoreFetcher.fetchWorkouts(dateRange: dateRange)
    return workouts.isEmpty ? nil : workouts.count
  }
  
  private func fetchMobilityMetrics(dateRange: DateRange) async -> BiologicalAgeHealthData.MobilityMetrics? {
    async let walkingSteadiness = fetchWalkingSteadiness(dateRange: dateRange)
    async let walkingSpeed = fetchWalkingSpeed(dateRange: dateRange)
    async let doubleSupportPercentage = fetchDoubleSupportPercentage(dateRange: dateRange)
    async let walkingAsymmetry = fetchWalkingAsymmetryPercentage(dateRange: dateRange)
    async let sixMinuteWalk = fetchSixMinuteWalkDistance(dateRange: dateRange)
    async let stairAscentSpeed = fetchStairAscentSpeed(dateRange: dateRange)
    async let stairDescentSpeed = fetchStairDescentSpeed(dateRange: dateRange)

    let walkingSteadinessResult = await walkingSteadiness
    let walkingSpeedResult = await walkingSpeed
    let doubleSupportResult = await doubleSupportPercentage
    let walkingAsymmetryResult = await walkingAsymmetry
    let sixMinuteWalkResult = await sixMinuteWalk
    let stairAscentResult = await stairAscentSpeed
    let stairDescentResult = await stairDescentSpeed

    guard walkingSteadinessResult != nil || walkingSpeedResult != nil || doubleSupportResult != nil ||
          walkingAsymmetryResult != nil || sixMinuteWalkResult != nil ||
          stairAscentResult != nil || stairDescentResult != nil else {
      return nil
    }

    return BiologicalAgeHealthData.MobilityMetrics(
      walkingSteadiness: walkingSteadinessResult,
      walkingSpeed: walkingSpeedResult,
      doubleSupportPercentage: doubleSupportResult,
      walkingAsymmetryPercentage: walkingAsymmetryResult,
      sixMinuteWalkDistance: sixMinuteWalkResult,
      stairAscentSpeed: stairAscentResult,
      stairDescentSpeed: stairDescentResult
    )
  }

  private func fetchWalkingSteadiness(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.appleWalkingSteadiness),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }

    guard !samples.isEmpty else { return nil }

    let values = samples.map { $0.quantity.doubleValue(for: .percent()) * 100 }
    let average = values.reduce(0, +) / Double(values.count)

    return BiologicalAgeHealthData.MetricValue(
      value: String(format: "%.1f%%", average)
    )
  }

  private func fetchWalkingSpeed(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.walkingSpeed),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }

    guard !samples.isEmpty else { return nil }

    let speeds = samples.map { $0.quantity.doubleValue(for: .meter().unitDivided(by: .second())) }
    let averageSpeed = speeds.reduce(0, +) / Double(speeds.count)

    let unit = HKUnit.meter().unitDivided(by: .second())

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: unit, doubleValue: averageSpeed).displayString(for: unit, formatter: .twoDecimalPlaces)
    )
  }

  private func fetchDoubleSupportPercentage(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.walkingDoubleSupportPercentage),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }

    guard !samples.isEmpty else { return nil }

    let values = samples.map { $0.quantity.doubleValue(for: .percent()) * 100 }
    let average = values.reduce(0, +) / Double(values.count)

    return BiologicalAgeHealthData.MetricValue(
      value: String(format: "%.1f%%", average)
    )
  }

  private func fetchWalkingAsymmetryPercentage(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.walkingAsymmetryPercentage),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }

    guard !samples.isEmpty else { return nil }

    let values = samples.map { $0.quantity.doubleValue(for: .percent()) * 100 }
    let average = values.reduce(0, +) / Double(values.count)

    return BiologicalAgeHealthData.MetricValue(
      value: String(format: "%.1f%%", average)
    )
  }

  private func fetchSixMinuteWalkDistance(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.sixMinuteWalkTestDistance),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }

    guard !samples.isEmpty else { return nil }

    let distances = samples.map { $0.quantity.doubleValue(for: .meter()) }
    let average = distances.reduce(0, +) / Double(distances.count)

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: .meter(), doubleValue: average).displayString(for: .meter())
    )
  }

  private func fetchStairAscentSpeed(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.stairAscentSpeed),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }

    guard !samples.isEmpty else { return nil }

    let speeds = samples.map { $0.quantity.doubleValue(for: .meter().unitDivided(by: .second())) }
    let average = speeds.reduce(0, +) / Double(speeds.count)

    let unit = HKUnit.meter().unitDivided(by: .second())

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: unit, doubleValue: average).displayString(for: unit, formatter: .twoDecimalPlaces)
    )
  }

  private func fetchStairDescentSpeed(dateRange: DateRange) async -> BiologicalAgeHealthData.MetricValue? {
    let samples = await healthStoreFetcher.fetchSamples(
      for: HKQuantityType(.stairDescentSpeed),
      dateRange: dateRange
    ).compactMap { $0 as? HKQuantitySample }

    guard !samples.isEmpty else { return nil }

    let speeds = samples.map { $0.quantity.doubleValue(for: .meter().unitDivided(by: .second())) }
    let average = speeds.reduce(0, +) / Double(speeds.count)

    let unit = HKUnit.meter().unitDivided(by: .second())

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: unit, doubleValue: average).displayString(for: unit, formatter: .twoDecimalPlaces)
    )
  }

  private func fetchDaysWithCompleteMealLogging(dateRange: DateRange) async -> Set<Date> {
    let calendar = Calendar.current
    let days = calendar.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 7

    var completeDays = Set<Date>()

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

        // Check if all main meals are logged (excluding snacks)
        var hasBreakfast = false
        var hasLunch = false
        var hasDinner = false

        for log in foodItemLogs {
          switch log.meal {
          case .breakfast:
            hasBreakfast = true
          case .lunch:
            hasLunch = true
          case .dinner:
            hasDinner = true
          case .snack:
            // Snacks don't count toward meal completion
            break
          }
        }

        // Only count days where all three main meals are logged
        if hasBreakfast && hasLunch && hasDinner {
          completeDays.insert(dayStart)
        }
      } catch {
        print("Error fetching food logs: \(error)")
      }
    }

    return completeDays
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
    // First, identify days with complete meal logging
    let completeDays = await fetchDaysWithCompleteMealLogging(dateRange: dateRange)

    guard !completeDays.isEmpty else {
      // No complete logging days, can't calculate meaningful average
      return nil
    }

    let samples = await healthStoreFetcher.fetchCollatedQuantity(
      for: type,
      unit: unit,
      dateRange: dateRange
    )

    guard !samples.isEmpty else { return nil }

    // Filter samples to only include complete logging days
    let calendar = Calendar.current
    let validSamples = samples.filter { sample in
      let sampleDayStart = calendar.startOfDay(for: sample.date)
      return completeDays.contains(sampleDayStart)
    }

    guard !validSamples.isEmpty else { return nil }

    let dailyValues = validSamples.map { $0.quantity.doubleValue(for: unit) }
    let average = dailyValues.reduce(0, +) / Double(validSamples.count)

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: unit, doubleValue: average).displayString(for: unit)
    )
  }
  
  private func fetchDietQuality(dateRange: DateRange) async -> BiologicalAgeHealthData.NutritionMetrics.DietQuality? {
    // Get complete logging days
    let completeDays = await fetchDaysWithCompleteMealLogging(dateRange: dateRange)

    guard !completeDays.isEmpty else { return nil }

    var processedFoodCount = 0
    var totalFoodCount = 0
    var vegetableServings = 0.0

    for dayStart in completeDays {
      let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

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

    // Now dividing by actual complete logging days, not total days
    let averageVegetableServings = vegetableServings / Double(completeDays.count)

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

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: .pound(), doubleValue: averageWeight).displayString(for: .pound())
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

    return BiologicalAgeHealthData.MetricValue(
      value: await HKQuantity(unit: .count(), doubleValue: averageBMI).displayString(for: .count(), showUnits: false) + " kg/m²"
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

    return BiologicalAgeHealthData.MetricValue(
      value: String(format: "%.1f%%", averageBodyFat)
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
      daysSinceLastWorkout: daysSinceLastWorkout
    )
  }
  
  private func fetchBiologicalSex() async -> String? {
    return await MainActor.run {
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
  }
}
