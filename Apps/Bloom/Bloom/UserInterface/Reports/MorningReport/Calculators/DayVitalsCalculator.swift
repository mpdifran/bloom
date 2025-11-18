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
    async let trainingLoad = generateTrainingLoadData(for: date)
    async let mindfulness = generateMindfulnessData(for: date)
    async let menstrualHealth = generateMenstrualHealthData(for: date)
    async let digestiveHealth = generateDigestiveHealthData(for: date)

    let (activityResult, bodyCompositionResult, heartHealthResult, nutritionResult, sleepResult, stressResult, exerciseResult, trainingLoadResult, mindfulnessResult, menstrualHealthResult, digestiveHealthResult) = await (
      activity,
      bodyComposition,
      heartHealth,
      nutrition,
      sleep,
      stress,
      exercise,
      trainingLoad,
      mindfulness,
      menstrualHealth,
      digestiveHealth
    )

    return DayVitalsData(
      date: date,
      activity: activityResult,
      bodyComposition: bodyCompositionResult,
      heartHealth: heartHealthResult,
      nutrition: nutritionResult,
      sleep: sleepResult,
      stress: stressResult,
      exercise: exerciseResult,
      trainingLoad: trainingLoadResult,
      mindfulness: mindfulnessResult,
      menstrualHealth: menstrualHealthResult,
      digestiveHealth: digestiveHealthResult
    )
  }
}

// MARK: - Activity Data
private extension DayVitalsCalculator {
  
  func generateActivityData(for date: Date) async -> ActivityData? {
    let dateRange = DateRange.duringDay(date)
    let previousWeekRange = DateRange.trailingDays(from: date, numberOfDays: 7)

    // Fetch current day data
    async let basalEnergy = HealthStoreFetcher.shared.fetchTotalQuantity(for: .basalEnergyBurned, dateRange: dateRange)
    async let activeEnergy = HealthStoreFetcher.shared.fetchTotalQuantity(for: .activeEnergyBurned, dateRange: dateRange)
    async let steps = HealthStoreFetcher.shared.fetchTotalQuantity(for: .stepCount, dateRange: dateRange)
    async let walkingDistance = HealthStoreFetcher.shared.fetchTotalQuantity(for: .distanceWalkingRunning, dateRange: dateRange)

    // Fetch previous week data for trends
    async let previousBasalEnergy = HealthStoreFetcher.shared.fetchCollatedQuantity(for: .basalEnergyBurned, unit: .largeCalorie(), dateRange: previousWeekRange)
    async let previousActiveEnergy = HealthStoreFetcher.shared.fetchCollatedQuantity(for: .activeEnergyBurned, unit: .largeCalorie(), dateRange: previousWeekRange)
    async let previousSteps = HealthStoreFetcher.shared.fetchCollatedQuantity(for: .stepCount, unit: .count(), dateRange: previousWeekRange)
    async let previousWalkingDistance = HealthStoreFetcher.shared.fetchCollatedQuantity(for: .distanceWalkingRunning, unit: .mile(), dateRange: previousWeekRange)

    let (basalResult, activeResult, stepsResult, walkingResult, prevBasal, prevActive, prevSteps, prevWalking) = await (
      basalEnergy, activeEnergy, steps, walkingDistance,
      previousBasalEnergy, previousActiveEnergy, previousSteps, previousWalkingDistance
    )

    guard let basal = basalResult, let active = activeResult else { return nil }

    let totalEnergy = basal.sum(active, unit: .largeCalorie())

    // Create metrics with trends
    let basalMetric = await createMetricWithTrend(
      current: basal,
      unit: .largeCalorie(),
      previous: prevBasal.map { $0.quantity },
      formatter: .noDecimalPlaces
    )

    let activeMetric = await createMetricWithTrend(
      current: active,
      unit: .largeCalorie(),
      previous: prevActive.map { $0.quantity },
      formatter: .noDecimalPlaces
    )

    let totalMetric = await createMetricWithTrend(
      current: totalEnergy,
      unit: .largeCalorie(),
      previous: prevBasal.compactMap { basalSample in
        prevActive.first { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) }
          .map { activeSample in basalSample.quantity.sum(activeSample.quantity, unit: .largeCalorie()) }
      },
      formatter: .noDecimalPlaces
    )

    let stepsMetric: MetricWithTrend? = if let stepsResult {
      await createMetricWithTrend(
        current: stepsResult,
        unit: .count(),
        previous: prevSteps.map { $0.quantity },
        formatter: .noDecimalPlaces
      )
    } else {
      nil
    }

    let walkingMetric: MetricWithTrend? = if let walkingResult {
      await createMetricWithTrend(
        current: walkingResult,
        unit: .mile(),
        previous: prevWalking.map { $0.quantity },
        formatter: .oneDecimalPlace
      )
    } else {
      nil
    }

    return ActivityData(
      basalEnergyBurned: basalMetric,
      activeEnergyBurned: activeMetric,
      totalEnergyBurned: totalMetric,
      steps: stepsMetric,
      walkingDistance: walkingMetric
    )
  }

  private func createMetricWithTrend(
    current: HKQuantity,
    unit: HKUnit,
    previous: [HKQuantity],
    formatter: NumberFormatter
  ) async -> MetricWithTrend {
    let value = await current.displayString(for: unit, formatter: formatter)
    let currentValue = current.doubleValue(for: unit)
    let previousValues = previous.map { $0.doubleValue(for: unit) }
    let trend = TrendCalculator.calculateTrend(current: currentValue, previous: previousValues)

    return MetricWithTrend(value: value, trend: trend)
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
    
    let bodyFatPercentageString = bodyFatQuantity.map { quantity in
      let percent = quantity.doubleValue(for: .percent()) * 100
      return "\(Int(percent))%"
    }
    
    let bodyFatPercentageAverageString = bodyCompositionSummary?.details.bodyFatPercentage.map { quantity in
      let percent = quantity.doubleValue(for: .percent()) * 100
      return "\(Int(percent))%"
    }
    
    return BodyCompositionData(
      bodyMass: await bodyMassQuantity?.displayString(for: bodyMassUnit, formatter: .oneDecimalPlace),
      bodyMassAverage: await bodyCompositionSummary?.details.averageBodyMass?.displayString(for: bodyMassUnit, formatter: .oneDecimalPlace),
      bodyFatPercentage: bodyFatPercentageString,
      bodyFatPercentageAverage: bodyFatPercentageAverageString,
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
    
    return await NutritionData(
      totalCalories: await caloriesResult?.displayString(for: .largeCalorie(), formatter: .noDecimalPlaces) ?? "0 cal",
      protein: await proteinResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      carbohydrates: await carbsResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      fat: await fatResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      saturatedFat: await saturatedFatResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      fiber: await fiberResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      sugar: await sugarResult?.displayString(for: .gram(), formatter: .noDecimalPlaces),
      sodium: await sodiumResult?.displayString(for: .gramUnit(with: .milli), formatter: .noDecimalPlaces),
      hydration: {
        guard let waterResult = waterResult else { return nil }
        let previousWeekRange = DateRange.trailingDays(from: date, numberOfDays: 7)
        let previousWater = await HealthStoreFetcher.shared.fetchCollatedQuantity(for: .dietaryWater, unit: .literUnit(with: .milli), dateRange: previousWeekRange)
        return await createMetricWithTrend(
          current: waterResult,
          unit: .literUnit(with: .milli),
          previous: previousWater.map { $0.quantity },
          formatter: .oneDecimalPlace
        )
      }(),
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
    guard let sleepSession = await CentralizedSleepCalculator.shared.calculateSleepSessionForTodayInsights(for: date) else {
      return nil
    }

    return SleepData(sleepSession: sleepSession)
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

// MARK: - Training Load Data
private extension DayVitalsCalculator {
  
  func generateTrainingLoadData(for date: Date) async -> TrainingLoadData? {
    let dateRange = DateRange.duringDay(date)
    
    let workouts = await HealthStoreFetcher.shared.fetchWorkouts(dateRange: dateRange)
    guard workouts.isNotEmpty else { return nil }
    
    var workoutEffortData = [WorkoutEffortData]()
    
    for workout in workouts {
      let duration = workout.duration / 60 // Convert to minutes
      
      // Fetch user-provided effort score for this workout
      let userEffortScore = ((try? await HealthStoreFetcher.shared.fetchSamples(
        for: HKQuantityType(.workoutEffortScore),
        dateRange: DateRange(workout.startDate, workout.endDate)
      )) as? [HKQuantitySample])?.first?.quantity.doubleValue(for: .appleEffortScore())

      // Fetch estimated effort score for this workout
      let estimatedEffortScore = ((try? await HealthStoreFetcher.shared.fetchSamples(
        for: HKQuantityType(.estimatedWorkoutEffortScore),
        dateRange: DateRange(workout.startDate, workout.endDate)
      )) as? [HKQuantitySample])?.first?.quantity.doubleValue(for: .appleEffortScore())
      
      // Use user score if available, otherwise estimated score
      let effortScore = userEffortScore ?? estimatedEffortScore
      
      let effortLevel = effortScore.map { score in
        switch score {
        case 0...3: return "Easy"
        case 4...6: return "Moderate" 
        case 7...8: return "Hard"
        case 9...10: return "All Out"
        default: return "Unknown"
        }
      }
      
      let workoutEffortDataItem = WorkoutEffortData(
        workoutType: workout.workoutActivityType.name,
        startTime: workout.startDate,
        duration: await HKQuantity(unit: .minute(), doubleValue: duration).displayString(for: .minute(), formatter: .noDecimalPlaces),
        userEffortScore: userEffortScore.map { String(format: "%.1f", $0) },
        estimatedEffortScore: estimatedEffortScore.map { String(format: "%.1f", $0) },
        effortLevel: effortLevel
      )
      
      workoutEffortData.append(workoutEffortDataItem)
    }
    
    // Get training load summary from calculator
    let trainingLoadSummary = await TrainingLoadCalculator.shared.trainingLoadSummary
    await TrainingLoadCalculator.shared.refreshTrainingLoad()
    
    return TrainingLoadData(
      workoutEffortScores: workoutEffortData,
      percentageDifference: trainingLoadSummary.map { String(format: "%.0f", $0.percentageDifference) },
      trainingLoadStatus: trainingLoadSummary?.status.rawValue
    )
  }
}

// MARK: - New Health Metrics
private extension DayVitalsCalculator {

  func generateMindfulnessData(for date: Date) async -> MetricWithTrend? {
    let dateRange = DateRange.duringDay(date)
    let previousWeekRange = DateRange.trailingDays(from: date, numberOfDays: 7)

    // Fetch mindful sessions for the day
    let mindfulSessions = ((try? await HealthStoreFetcher.shared.fetchSamples(
      for: HKCategoryType(.mindfulSession),
      dateRange: dateRange
    )) ?? []).compactMap { $0 as? HKCategorySample }

    guard !mindfulSessions.isEmpty else { return nil }

    // Calculate total mindfulness minutes for the day
    let totalMinutes = mindfulSessions.reduce(0.0) { total, session in
      total + session.endDate.timeIntervalSince(session.startDate) / 60.0
    }

    // Fetch previous week data for trend
    let previousSessions = ((try? await HealthStoreFetcher.shared.fetchSamples(
      for: HKCategoryType(.mindfulSession),
      dateRange: previousWeekRange
    )) ?? []).compactMap { $0 as? HKCategorySample }

    // Calculate daily averages for previous week
    var dailyMinutes: [Double] = []
    Calendar.current.iterate(dateRange: previousWeekRange, by: DateComponents(day: 1)) { iterDate in
      let dayMinutes = previousSessions
        .filter { Calendar.current.isDate($0.startDate, inSameDayAs: iterDate) }
        .reduce(0.0) { total, session in
          total + session.endDate.timeIntervalSince(session.startDate) / 60.0
        }
      if dayMinutes > 0 {
        dailyMinutes.append(dayMinutes)
      }
    }

    let value = await HKQuantity(unit: .minute(), doubleValue: totalMinutes)
      .displayString(for: .minute(), formatter: .noDecimalPlaces)
    let trend = TrendCalculator.calculateTrend(current: totalMinutes, previous: dailyMinutes)

    return MetricWithTrend(value: value, trend: trend)
  }

  func generateMenstrualHealthData(for date: Date) async -> MenstrualHealthData? {
    // Only include menstrual data for female users
    let isFemale = await HealthManager.shared.sex() == .female
    guard isFemale else { return nil }

    // Use the already-calculated menstrual summary from VitalsCalculator
    guard let menstrualSummary = await VitalsCalculator.shared.menstrualSummary else { return nil }
    guard !menstrualSummary.hasNoData else { return nil }
    guard let mostRecentCycle = menstrualSummary.mostRecentCycle else { return nil }

    // Calculate days since last period
    let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: mostRecentCycle.startDate, to: date).day ?? 0
    let dayInCycle = daysSinceLastPeriod + 1

    // Get phase from VitalsCalculator
    let phase = menstrualSummary.currentPhase()
    let cyclePhase: String?
    let dayInCurrentPhase: Int?

    switch phase {
    case .menstrual:
      cyclePhase = "menstrual"
      // Day in menstrual phase is same as day in cycle (starts at 1)
      dayInCurrentPhase = dayInCycle
    case .follicular:
      cyclePhase = "follicular"
      // Follicular phase starts after menstruation ends
      let menstruationDays = menstrualSummary.averageMenstruationDays ?? 5
      dayInCurrentPhase = max(0, dayInCycle - menstruationDays)
    case .ovulation:
      cyclePhase = "ovulatory"
      let cycleDuration = menstrualSummary.averageCycleDuration ?? 28
      let ovulationDay = cycleDuration / 2
      // Day in ovulation window (1-3 days)
      dayInCurrentPhase = max(1, dayInCycle - ovulationDay + 2)
    case .luteal:
      cyclePhase = "luteal"
      let cycleDuration = menstrualSummary.averageCycleDuration ?? 28
      let ovulationDay = cycleDuration / 2
      dayInCurrentPhase = max(0, dayInCycle - ovulationDay - 1)
    case .unknown, .none:
      cyclePhase = nil
      dayInCurrentPhase = nil
    }

    // Calculate average cycle length with trend
    let averageCycleLength: MetricWithTrend?
    if let avgLength = menstrualSummary.averageCycleDuration {
      // Get previous cycle lengths for trend calculation
      let cycles = menstrualSummary.menstrualCycles.sorted { $0.startDate < $1.startDate }
      if cycles.count >= 2 {
        var cycleLengths: [Int] = []
        for i in 0..<(cycles.count - 1) {
          if let days = Calendar.current.dateComponents([.day], from: cycles[i].startDate, to: cycles[i + 1].startDate).day {
            cycleLengths.append(days)
          }
        }

        if !cycleLengths.isEmpty {
          let currentLength = cycleLengths.last ?? avgLength
          let previousLengths = cycleLengths.count > 1 ? Array(cycleLengths.dropLast()) : []
          let trend = previousLengths.isEmpty ? nil : TrendCalculator.calculateTrend(current: currentLength, previous: previousLengths)
          averageCycleLength = MetricWithTrend(value: "\(avgLength) days", trend: trend)
        } else {
          averageCycleLength = MetricWithTrend(value: "\(avgLength) days")
        }
      } else {
        averageCycleLength = MetricWithTrend(value: "\(avgLength) days")
      }
    } else {
      averageCycleLength = nil
    }

    // Get predicted next period date
    let predictedNextPeriodDate = menstrualSummary.nextPredictedPeriodDate
    let predictedNextPeriodDateString = predictedNextPeriodDate.map { DateFormatter.mediumDateShortTime.string(from: $0) }

    // Calculate days until next period
    let daysUntilNextPeriod: Int?
    let predictedNextPeriod: String?
    if let predictionDate = predictedNextPeriodDate {
      let days = Calendar.current.dateComponents([.day], from: date, to: predictionDate).day ?? 0
      daysUntilNextPeriod = days > 0 ? days : nil
      predictedNextPeriod = days > 0 ? "in \(days) days" : nil
    } else {
      daysUntilNextPeriod = nil
      predictedNextPeriod = nil
    }

    return MenstrualHealthData(
      currentCyclePhase: cyclePhase,
      dayInCycle: dayInCycle,
      daysSinceLastPeriod: daysSinceLastPeriod,
      averageCycleLength: averageCycleLength,
      predictedNextPeriod: predictedNextPeriod,
      predictedNextPeriodDate: predictedNextPeriodDateString,
      daysUntilPredictedPeriod: daysUntilNextPeriod,
      isMenstruating: menstrualSummary.isMenstruating,
      dayInCurrentPhase: dayInCurrentPhase
    )
  }

  func generateDigestiveHealthData(for date: Date) async -> DigestiveHealthData? {
    let dateRange = DateRange.duringDay(date)
    let previousWeekRange = DateRange.trailingDays(from: date, numberOfDays: 7)

    // Fetch yesterday's bowel movements
    do {
      let yesterdayMovements = try await bowelMovementModelActor.fetchBowelMovements(dateRange: dateRange)

      // Calculate regularity score based on BowelMovementMonthlySummary logic
      let monthlyMovements = try await bowelMovementModelActor.fetchBowelMovements(
        dateRange: DateRange.trailingDays(from: date, numberOfDays: 30)
      )

      // Return nil if there's no bowel movement data at all
      guard yesterdayMovements.isNotEmpty || monthlyMovements.isNotEmpty else {
        return nil
      }

      // Convert to samples for API
      let movementSamples = yesterdayMovements.map { movement in
        BowelMovementSample(
          time: DateFormatter.justTimeShort.string(from: movement.date),
          bristolScore: movement.bristolStoolType,
          duration: movement.duration.name
        )
      }

      // Fetch previous week data for trends
      let previousMovements = try await bowelMovementModelActor.fetchBowelMovements(dateRange: previousWeekRange)

      // Calculate daily movement counts for trend
      var dailyCounts: [Int] = []
      Calendar.current.iterate(dateRange: previousWeekRange, by: DateComponents(day: 1)) { iterDate in
        let dayCount = previousMovements.filter { Calendar.current.isDate($0.date, inSameDayAs: iterDate) }.count
        dailyCounts.append(dayCount)
      }

      let avgDailyMovements: MetricWithTrend?
      if !dailyCounts.isEmpty {
        let average = Double(dailyCounts.reduce(0, +)) / Double(dailyCounts.count)
        let value = String(format: "%.1f/day", average)
        let trend = TrendCalculator.calculateTrend(current: yesterdayMovements.count, previous: dailyCounts)
        avgDailyMovements = MetricWithTrend(value: value, trend: trend)
      } else {
        avgDailyMovements = nil
      }

      let summary = BowelMovementMonthlySummary(bowelMovements: monthlyMovements)

      let regularityScore: MetricWithTrend?
      if let rating = summary.rating {
        let scoreValue = rating.name
        // For simplicity, we won't calculate regularity trend for now
        regularityScore = MetricWithTrend(value: scoreValue)
      } else {
        regularityScore = nil
      }

      // Days since last movement
      let daysSinceLastMovement: Int?
      if yesterdayMovements.isEmpty {
        if let lastMovement = monthlyMovements.sorted(by: { $0.date > $1.date }).first {
          daysSinceLastMovement = Calendar.current.dateComponents([.day], from: lastMovement.date, to: date).day
        } else {
          daysSinceLastMovement = nil
        }
      } else {
        daysSinceLastMovement = nil
      }

      return DigestiveHealthData(
        yesterdayMovements: movementSamples,
        averageDailyMovements: avgDailyMovements,
        regularityScore: regularityScore,
        daysSinceLastMovement: daysSinceLastMovement
      )

    } catch {
      return nil
    }
  }
}
