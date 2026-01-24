//
//  ChatHealthQueryPerformer.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Foundation
import BloomModel
import BloomFoundation
import HealthKit
import DataContainer
import CoreHealth
@preconcurrency import CoreNetwork

final class ChatHealthQueryPerformer: Sendable {

  init() { }

  private let foodLogModelActor = FoodItemLogModelActor.standard()
  private let bowelMovementModelActor = BowelMovementModelActor.standard()
  private let modelActor = HabitModelActor.standard()

  private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      let dateString = DateFormatter.dateTimeMediumWithTimeZone.string(from: date)
      try container.encode(dateString)
    }
    return encoder
  }()
}

extension ChatHealthQueryPerformer {

  func perform(query: SocketMessage.Query) async -> String {
    print("Querying Health Data [\(query.dataType.rawValue)] \(query.startDate) to \(query.endDate)")

    let results: String
    switch query.dataType {
    case .nutrition:
      let nutrition = await fetchNutrition(query: query)
      let foodLogs = await fetchFoodLogs(query: query)

      results = foodLogs + "\n\n" + nutrition
    case .goals:
      results = await fetchGoals(query: query)
    case .activityLevel:
      results = await fetchActivityLevel(query: query)
    case .bodyWeight:
      results = await fetchBodyWeight(query: query)
    case .bowelMovements:
      results = await fetchBowelMovements(query: query)
    case .heart:
      results = await fetchHeart(query: query)
    case .menstruation:
      results = await fetchMenstruation(query: query)
    case .sleep:
      results = await fetchSleep(query: query)
    case .stress:
      results = await fetchStress(query: query)
    case .workouts:
      results = await fetchWorkouts(query: query)
    case .targetHeartRateZoneMinutes:
      results = await fetchTargetHeartRateZoneMinutes(query: query)
    case .caloricIntake:
      results = await fetchHealthMetric(.calories, dateRange: query.dateRange)
    case .proteinIntake:
      results = await fetchHealthMetric(.proteinIntake, dateRange: query.dateRange)
    case .waterIntake:
      results = await fetchHealthMetric(.waterIntake, dateRange: query.dateRange)
    case .fiberIntake:
      results = await fetchHealthMetric(.fiberIntake, dateRange: query.dateRange)
    case .meditationMinutes:
      results = await fetchHealthMetric(.meditationMinutes, dateRange: query.dateRange)
    case .exerciseMinutes:
      results = await fetchHealthMetric(.exerciseMinutes, dateRange: query.dateRange)
    case .stepCount:
      results = await fetchHealthMetric(.stepCount, dateRange: query.dateRange)
    case .walkingRunningDistance:
      results = await fetchHealthMetric(.walkingRunningDistance, dateRange: query.dateRange)
    case .runDistance:
      results = await fetchHealthMetric(.runDistance, dateRange: query.dateRange)
    case .runDuration:
      results = await fetchHealthMetric(.runDuration, dateRange: query.dateRange)
    case .bikeDistance:
      results = await fetchHealthMetric(.bikeDistance, dateRange: query.dateRange)
    case .bikeDuration:
      results = await fetchHealthMetric(.bikeDuration, dateRange: query.dateRange)
    case .mobilityAndFlexibilityDuration:
      results = await fetchHealthMetric(.mobilityAndFlexibilityDuration, dateRange: query.dateRange)
    case .strengthTrainingDuration:
      results = await fetchHealthMetric(.strengthTrainingDuration, dateRange: query.dateRange)
    case .cardioDuration:
      results = await fetchHealthMetric(.cardioDuration, dateRange: query.dateRange)
    case .highIntensityIntervalTrainingDuration:
      results = await fetchHealthMetric(.highIntensityIntervalTrainingDuration, dateRange: query.dateRange)
    case .reminders:
      results = await fetchReminders(query: query)
    }

    print("Returning Health Data [\(query.dataType.rawValue)]\n\(results)")
    return results
  }
}

private extension ChatHealthQueryPerformer {

  func fetchHealthMetric(_ metric: SuggestedGoal.Metric, dateRange: DateRange) async -> String {
    let targetMetric = metric.targetMetric
    let unit = targetMetric.defaultUnit
    let dailyQuantities = await targetMetric.fetchCollatedDailyQuantity(
      unit: unit,
      dateRange: dateRange
    )

    guard dailyQuantities.isNotEmpty else { 
      return convertToString(value: ChatHealthMetricData(samples: []))
    }

    var samples = [ChatHealthMetricData.Sample]()
    for dailyQuantity in dailyQuantities {
      await samples.append(
        ChatHealthMetricData.Sample(
          date: dailyQuantity.date,
          value: dailyQuantity.quantity.displayString(for: unit)
        )
      )
    }

    return convertToString(value: ChatHealthMetricData(samples: samples))
  }

  func fetchFoodLogs(query: SocketMessage.Query) async -> String {
    var logs = [HealthVitalData.FoodLogDay]()

    await Calendar.current.asyncIterate(
      dateRange: query.dateRange.extendToEndOfDay(), // Food logs have hard coded times. Do this to make sure we capture everything within a day.
      by: DateComponents(day: 1)
    ) { [foodLogModelActor] (date) in
      do {
        let foodLogs = try await foodLogModelActor.fetchLogs(for: date)

        var breakfast = [HealthVitalData.FoodItem]()
        var lunch = [HealthVitalData.FoodItem]()
        var dinner = [HealthVitalData.FoodItem]()
        var snack = [HealthVitalData.FoodItem]()

        for foodLog in foodLogs {
          for serving in foodLog.foodItemServings {
            guard let foodItem = serving.foodItem else { continue }

            let networkFoodItem = HealthVitalData.FoodItem(foodItemLog: foodLog, foodItem: foodItem)

            switch foodLog.meal {
            case .breakfast:
              breakfast.append(networkFoodItem)
            case .lunch:
              lunch.append(networkFoodItem)
            case .dinner:
              dinner.append(networkFoodItem)
            case .snack:
              snack.append(networkFoodItem)
            @unknown default:
              print("UNKNOWN MEAL CASE: \(foodLog.meal.name)")
              break
            }
          }
        }

        guard
          breakfast.isNotEmpty ||
          lunch.isNotEmpty ||
          dinner.isNotEmpty ||
          snack.isNotEmpty
        else { return }

        let dayLog = HealthVitalData.FoodLogDay(
          date: DateFormatter.justDateShort.string(from: date),
          breakfast: breakfast,
          lunch: lunch,
          dinner: dinner,
          snack: snack
        )
        logs.append(dayLog)
      } catch {
        print(error)
      }
    }
    return convertToString(value: logs)
  }

  func fetchNutrition(query: SocketMessage.Query) async -> String {
    let dateRange = query.dateRange
    let averages = HealthVitalData.NutritionAverages(
      averageProtein: await formattedAverage(for: .dietaryProtein, unit: .gram(), dateRange: dateRange),
      averageCarbohydrates: await formattedAverage(for: .dietaryCarbohydrates, unit: .gram(), dateRange: dateRange),
      averageFat: await formattedAverage(for: .dietaryFatTotal, unit: .gram(), dateRange: dateRange),
      averageSaturatedFat: await formattedAverage(for: .dietaryFatSaturated, unit: .gram(), dateRange: dateRange),
      averagePolyunsaturatedFat: await formattedAverage(for: .dietaryFatPolyunsaturated, unit: .gram(), dateRange: dateRange),
      averageMonounsaturatedFat: await formattedAverage(for: .dietaryFatMonounsaturated, unit: .gram(), dateRange: dateRange),
      averageFiber: await formattedAverage(for: .dietaryFiber, unit: .gram(), dateRange: dateRange),
      averageSugar: await formattedAverage(for: .dietarySugar, unit: .gram(), dateRange: dateRange),
      averageCholesterol: await formattedAverage(for: .dietaryCholesterol, unit: .gramUnit(with: .milli), dateRange: dateRange),
      averageCalcium: await formattedAverage(for: .dietaryCalcium, unit: .gramUnit(with: .milli), dateRange: dateRange),
      averageIron: await formattedAverage(for: .dietaryIron, unit: .gramUnit(with: .milli), dateRange: dateRange),
      averageMagnesium: await formattedAverage(for: .dietaryMagnesium, unit: .gramUnit(with: .milli), dateRange: dateRange),
      averagePotassium: await formattedAverage(for: .dietaryPotassium, unit: .gramUnit(with: .milli), dateRange: dateRange),
      averageSodium: await formattedAverage(for: .dietarySodium, unit: .gramUnit(with: .milli), dateRange: dateRange),
      averageZinc: await formattedAverage(for: .dietaryZinc, unit: .gramUnit(with: .milli), dateRange: dateRange),
      averageVitaminA: await formattedAverage(for: .dietaryVitaminA, unit: .gramUnit(with: .micro), dateRange: dateRange),
      averageVitaminB6: await formattedAverage(for: .dietaryVitaminB6, unit: .gramUnit(with: .milli), dateRange: dateRange),
      averageVitaminB12: await formattedAverage(for: .dietaryVitaminB12, unit: .gramUnit(with: .micro), dateRange: dateRange),
      averageVitaminC: await formattedAverage(for: .dietaryVitaminC, unit: .gramUnit(with: .milli), dateRange: dateRange),
      averageVitaminD: await formattedAverage(for: .dietaryVitaminD, unit: .gramUnit(with: .micro), dateRange: dateRange),
      averageVitaminE: await formattedAverage(for: .dietaryVitaminE, unit: .gramUnit(with: .milli), dateRange: dateRange)
    )

    let nutrition = HealthVitalData.Nutrition(
      nutritionAverages: averages,
      foodLogs: []
    )
    return convertToString(value: nutrition)
  }

  func fetchGoals(query: SocketMessage.Query) async -> String {
    do {
      let activeGoals = try await modelActor.fetchActiveHabits().filter { $0.targetMetric.metric != nil }

      var goalSummaries = [GoalSummary]()
      for goal in activeGoals {
        guard let metric = goal.targetMetric.metric else { continue }

        let summary = await GoalSummary(
          metric: metric,
          goal: goal.displayQuantity
        )
        goalSummaries.append(summary)
      }

      let currentGoalsData = CurrentGoalsData(currentGoals: goalSummaries)

      return convertToString(value: currentGoalsData)
    } catch {
      return "There was an error querying this data."
    }
  }

  func fetchActivityLevel(query: SocketMessage.Query) async -> String {
    let dateRange = query.dateRange
    let unit = HKUnit.largeCalorie()
    let basalEnergy = await HealthStoreFetcher.shared.fetchCollatedQuantity(
      for: .basalEnergyBurned,
      unit: unit,
      dateRange: dateRange
    )
    let activeEnergy = await HealthStoreFetcher.shared.fetchCollatedQuantity(
      for: .activeEnergyBurned,
      unit: unit,
      dateRange: dateRange
    )

    guard basalEnergy.isNotEmpty || activeEnergy.isNotEmpty else { 
      return convertToString(value: HealthVitalData.ActivityLevel(basalEnergyBurned: [], activeEnergyBurned: []))
    }

    let basalSamples = basalEnergy.map { sample in
      HealthVitalData.Sample(date: sample.date, quantity: sample.quantity.chatQuantity(for: unit, numberFormatter: .noDecimalPlaces))
    }
    let activeSamples = activeEnergy.map { sample in
      HealthVitalData.Sample(date: sample.date, quantity: sample.quantity.chatQuantity(for: unit, numberFormatter: .noDecimalPlaces))
    }

    let bioAgeSummary = await fetchBioAgeSummary(for: [.zoneMinutes, .activityLevel])

    let activityLevel = HealthVitalData.ActivityLevel(
      basalEnergyBurned: basalSamples,
      activeEnergyBurned: activeSamples,
      bioAgeSummary: bioAgeSummary
    )

    return convertToString(value: activityLevel)
  }

  func fetchBodyWeight(query: SocketMessage.Query) async -> String {
    let dateRange = query.dateRange

    let bodyFatPercentage = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .bodyFatPercentage,
      unit: .percent(),
      dateRange: dateRange
    )
    let bodyMass = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .bodyMass,
      unit: .gramUnit(with: .kilo),
      dateRange: dateRange
    )

    guard bodyFatPercentage.isNotEmpty || bodyMass.isNotEmpty else { 
      return convertToString(value: HealthVitalData.BodyComposition(bodyFatPercentage: [], bodyMass: []))
    }

    let bodyFatSamples = bodyFatPercentage.map {
      HealthVitalData.Sample(
        date: $0.date,
        quantity: $0.quantity.chatQuantity(for: .percent(), numberFormatter: .noDecimalPlaces)
      )
    }
    let bodyMassUnit = await HKUnit.gramUnit(with: .kilo).localizedUnit()
    let bodyMassSamples = bodyMass.map {
      HealthVitalData.Sample(
        date: $0.date,
        quantity: $0.quantity.chatQuantity(for: bodyMassUnit, numberFormatter: .oneDecimalPlace)
      )
    }

    let bioAgeSummary = await fetchBioAgeSummary(for: [.bodyFatPercentage])

    let bodyComposition = HealthVitalData.BodyComposition(
      bodyFatPercentage: bodyFatSamples,
      bodyMass: bodyMassSamples,
      bioAgeSummary: bioAgeSummary
    )

    return convertToString(value: bodyComposition)
  }

  func fetchBowelMovements(query: SocketMessage.Query) async -> String {
    do {
      let bowelMovementSamples = try await bowelMovementModelActor.fetchBowelMovements(dateRange: query.dateRange)

      let samples = bowelMovementSamples.map {
        HealthVitalData.BowelMovementSample(
          date: $0.date,
          bristolStoolType: $0.bristolStoolType,
          duration: $0.duration.name
        )
      }

      guard samples.isNotEmpty else {
        return convertToString(value: HealthVitalData.BowelMovements(samples: []))
      }

      let bowelMovements = HealthVitalData.BowelMovements(samples: samples, bioAgeSummary: nil)

      return convertToString(value: bowelMovements)
    } catch {
      return "There was an error querying this data."
    }
  }

  func fetchHeart(query: SocketMessage.Query) async -> String {
    let dateRange = query.dateRange

    let vo2Max = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .vo2Max,
      unit: .vo2Max(),
      dateRange: dateRange
    )
    let rhr = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .restingHeartRate,
      unit: .bpm(),
      dateRange: dateRange
    )
    let heartRateRecovery = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .heartRateRecoveryOneMinute,
      unit: .bpm(),
      dateRange: dateRange
    )

    guard vo2Max.isNotEmpty || rhr.isNotEmpty || heartRateRecovery.isNotEmpty else {
      return convertToString(
        value: HealthVitalData.HeartHealth(
          vo2Max: [],
          restingHeartRate: [],
          heartRateRecoveryOneMinute: []
        )
      )
    }

    let vo2MaxSamples = vo2Max.map {
      HealthVitalData.Sample(date: $0.date, quantity: $0.quantity.chatQuantity(for: .vo2Max(), numberFormatter: .noDecimalPlaces))
    }
    let rhrSamples = rhr.map {
      HealthVitalData.Sample(date: $0.date, quantity: $0.quantity.chatQuantity(for: .bpm(), unitOverride: "bpm", numberFormatter: .noDecimalPlaces))
    }
    let heartRateRecoverySamples = heartRateRecovery.map {
      HealthVitalData.Sample(date: $0.date, quantity: $0.quantity.chatQuantity(for: .bpm(), unitOverride: "bpm", numberFormatter: .noDecimalPlaces))
    }

    let bioAgeSummary = await fetchBioAgeSummary(for: [
      .vo2Max, .restingHeartRate, .heartRateRecovery, .hrvTrend, .heartRateReserve
    ])

    let heartHealth = HealthVitalData.HeartHealth(
      vo2Max: vo2MaxSamples,
      restingHeartRate: rhrSamples,
      heartRateRecoveryOneMinute: heartRateRecoverySamples,
      bioAgeSummary: bioAgeSummary
    )

    return convertToString(value: heartHealth)
  }

  func fetchMenstruation(query: SocketMessage.Query) async -> String {
    let dateRange = query.dateRange

    let cycles = await HealthStoreFetcher.shared.fetchMenstrualFlowSamples(dateRange: dateRange)

    let cycleSamples = cycles.compactMap { (cycle) -> HealthVitalData.MenstrualCycle? in
      return HealthVitalData.MenstrualCycle(
        startDate: cycle.startDate,
        flowSamples: cycle.samples.map { sample in
          HealthVitalData.MenstrualFlowLevelSample(
            date: sample.startDate,
            flowLevel: sample.menstrualFlowCategory.chatFlowLevel
          )
        }
      )
    }

    guard cycleSamples.isNotEmpty else { 
      return convertToString(value: HealthVitalData.MenstrualHealth(cycles: []))
    }

    let menstrualHealth = HealthVitalData.MenstrualHealth(cycles: cycleSamples)

    return convertToString(value: menstrualHealth)
  }

  func fetchSleep(query: SocketMessage.Query) async -> String {
    let dateRange = query.dateRange
    let sleepAnalyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: dateRange)

    guard sleepAnalyses.isNotEmpty else { 
      return convertToString(value: HealthVitalData.Sleep(sleepDetails: []))
    }

    let sleepDays = sleepAnalyses.map { sleepAnalysis in
      let respiratoryRateQuantity: HealthVitalData.Quantity?
      let averageRespiratoryRate = sleepAnalysis.respiratoryRate.average(keyPath: \.averageRespiratoryRate)
      if averageRespiratoryRate > 0 {
        respiratoryRateQuantity = HealthVitalData.Quantity(
          value: averageRespiratoryRate,
          unit: "breaths / minute",
          numberFormatter: .oneDecimalPlace
        )
      } else {
        respiratoryRateQuantity = nil
      }

      let soundLevelQuantity: HealthVitalData.Quantity?
      if sleepAnalysis.averageSoundLevel > 0 {
        soundLevelQuantity = HealthVitalData.Quantity(
          value: sleepAnalysis.averageSoundLevel,
          unit: HKUnit.decibelAWeightedSoundPressureLevel().unitString,
          numberFormatter: .noDecimalPlaces
        )
      } else {
        soundLevelQuantity = nil
      }

      let wristTempQuantity: HealthVitalData.Quantity?
      if let wristTemp = sleepAnalysis.wristTemperature?.averageWristTemperature, wristTemp > 0 {
        wristTempQuantity = HealthVitalData.Quantity(
          value: wristTemp,
          unit: HKUnit.degreeFahrenheit().unitString,
          numberFormatter: .oneDecimalPlace
        )
      } else {
        wristTempQuantity = nil
      }

      return HealthVitalData.SleepDay(
        start: sleepAnalysis.startDate,
        end: sleepAnalysis.endDate,
        deepSleep: sleepAnalysis.hasDetailedSleepCategories ? HealthVitalData.Quantity(value: sleepAnalysis.deepSleepMinutes, unit: "minute", numberFormatter: .noDecimalPlaces) : nil,
        coreSleep: sleepAnalysis.hasDetailedSleepCategories ? HealthVitalData.Quantity(value: sleepAnalysis.coreSleepMinutes, unit: "minute", numberFormatter: .noDecimalPlaces) : nil,
        remSleep: sleepAnalysis.hasDetailedSleepCategories ? HealthVitalData.Quantity(value: sleepAnalysis.remSleepMinutes, unit: "minute", numberFormatter: .noDecimalPlaces) : nil,
        awakeSleep: sleepAnalysis.hasDetailedSleepCategories ? HealthVitalData.Quantity(value: sleepAnalysis.awakeSleepMinutes, unit: "minute", numberFormatter: .noDecimalPlaces) : nil,
        averageHeartRate: sleepAnalysis.averageHeartRate.map { HealthVitalData.Quantity(value: $0, unit: "bpm", numberFormatter: .noDecimalPlaces) },
        averageRespiratoryRate: respiratoryRateQuantity,
        averageDecibelAWeightedEnvironmentalSoundPressureLevel: soundLevelQuantity,
        wristTemperature: wristTempQuantity
      )
    }

    let bioAgeSummary = await fetchBioAgeSummary(for: [
      .sleepScore, .sleepDurationVariability, .bedtimeConsistency, .sleepHeartRate, .sleepRespiratoryRate
    ])

    let sleep = HealthVitalData.Sleep(sleepDetails: sleepDays, bioAgeSummary: bioAgeSummary)

    return convertToString(value: sleep)
  }

  func fetchStress(query: SocketMessage.Query) async -> String {
    let dateRange = query.dateRange
    let hrv = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .heartRateVariabilitySDNN,
      unit: .secondUnit(with: .milli),
      dateRange: dateRange
    )
    let systolic = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .bloodPressureSystolic,
      unit: .millimeterOfMercury(),
      dateRange: dateRange
    )
    let diastolic = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .bloodPressureDiastolic,
      unit: .millimeterOfMercury(),
      dateRange: dateRange
    )

    let hrvSamples = hrv.map {
      HealthVitalData.Sample(
        date: $0.date,
        quantity: $0.quantity.chatQuantity(for: .secondUnit(with: .milli), numberFormatter: .noDecimalPlaces)
      )
    }

    var bloodPressureSamples = [HealthVitalData.BloodPressureSample]()
    Calendar.current.iterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
      guard
        let systolicSample = systolic.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }),
        let diastolicSample = diastolic.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
      else {
        return
      }

      bloodPressureSamples.append(
        HealthVitalData.BloodPressureSample(
          date: systolicSample.date,
          systolic: systolicSample.quantity.chatQuantity(for: .millimeterOfMercury(), numberFormatter: .noDecimalPlaces),
          diastolic: diastolicSample.quantity.chatQuantity(for: .millimeterOfMercury(), numberFormatter: .noDecimalPlaces)
        )
      )
    }

    guard hrvSamples.isNotEmpty || bloodPressureSamples.isNotEmpty else { 
      return convertToString(value: HealthVitalData.Stress(heartRateVariability: [], bloodPressureSamples: []))
    }

    let bioAgeSummary = await fetchBioAgeSummary(for: [.bloodPressure, .hrvTrend])

    let stress = HealthVitalData.Stress(
      heartRateVariability: hrvSamples,
      bloodPressureSamples: bloodPressureSamples,
      bioAgeSummary: bioAgeSummary
    )

    return convertToString(value: stress)
  }

  func fetchWorkouts(query: SocketMessage.Query) async -> String {
    let dateRange = query.dateRange

    let workouts = await HealthStoreFetcher.shared.fetchWorkouts(dateRange: dateRange)

    guard workouts.isNotEmpty else {
      return convertToString(value: HealthVitalData.Workouts(workouts: []))
    }

    var workoutData = [HealthVitalData.Workout]()
    for workout in workouts {
      let averageHeartRateString: String?
      let avgHR = workout.averageHeartRate
      if avgHR.doubleValue(for: .bpm()) > 0 {
        averageHeartRateString = await avgHR.displayString(for: .bpm())
      } else {
        averageHeartRateString = nil
      }
      
      let elevationAscendedString: String?
      if let elevationAscended = workout.elevationAscended {
        elevationAscendedString = await elevationAscended.displayString(for: .meter())
      } else {
        elevationAscendedString = nil
      }
      
      let elevationDescendedString: String?
      if let elevationDescended = workout.elevationDescended {
        elevationDescendedString = await elevationDescended.displayString(for: .meter())
      } else {
        elevationDescendedString = nil
      }
      
      let data = await HealthVitalData.Workout(
        name: workout.workoutActivityType.name,
        start: workout.startDate,
        end: workout.endDate,
        duration: DateFormatter.timeIntervalHourMinuteSecondShort.string(from: workout.duration) ?? "00:00",
        activeEnergy: await workout.activeEnergyBurned.displayString(for: .largeCalorie()),
        totalEnergy: await workout.totalEnergyBurned.displayString(for: .largeCalorie()),
        distance: workout.totalDistanceWalkingRunningCycling?.displayString(for: .meterUnit(with: .kilo)),
        averageHeartRate: averageHeartRateString,
        elevationAscended: elevationAscendedString,
        elevationDescended: elevationDescendedString
      )
      workoutData.append(data)
    }

    let bioAgeSummary = await fetchBioAgeSummary(for: [
      .zoneMinutes, .activityLevel, .walkingSpeed, .stairClimbSpeed
    ])

    return convertToString(value: HealthVitalData.Workouts(workouts: workoutData, bioAgeSummary: bioAgeSummary))
  }

  func fetchTargetHeartRateZoneMinutes(query: SocketMessage.Query) async -> String {
    guard let heartRateZones = await HealthStoreFetcher.shared.heartRateZones() else {
      return convertToString(value: [HealthVitalData.HeartRateZoneWorkoutSample]())
    }

    let dateRange = query.dateRange

    let heartRateReports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)

    guard heartRateReports.isNotEmpty else { 
      return convertToString(value: [HealthVitalData.HeartRateZoneWorkoutSample]())
    }

    let samples = heartRateReports.map {
      HealthVitalData.HeartRateZoneWorkoutSample(
        start: $0.workout.startDate,
        end: $0.workout.endDate,
        workout: $0.workout.workoutActivityType.name,
        workoutDuration: $0.heartZoneDistribution.totalDuration.chatQuantity(for: .minute(), numberFormatter: .noDecimalPlaces),
        zone1Duration: $0.heartZoneDistribution.zone1.chatQuantity(for: .minute(), numberFormatter: .noDecimalPlaces),
        zone2Duration: $0.heartZoneDistribution.zone2.chatQuantity(for: .minute(), numberFormatter: .noDecimalPlaces),
        zone3Duration: $0.heartZoneDistribution.zone3.chatQuantity(for: .minute(), numberFormatter: .noDecimalPlaces),
        zone4Duration: $0.heartZoneDistribution.zone4.chatQuantity(for: .minute(), numberFormatter: .noDecimalPlaces),
        zone5Duration: $0.heartZoneDistribution.zone5.chatQuantity(for: .minute(), numberFormatter: .noDecimalPlaces)
      )
    }

    let zones = HealthVitalData.ExerciseEffectiveness(
      heartRateZones: HealthVitalData.HeartRateZones(
        heartRateReserve: HealthVitalData.Quantity(value: heartRateZones.heartRateReserve, unit: "bpm", numberFormatter: .noDecimalPlaces),
        restingHeartRate: HealthVitalData.Quantity(value: heartRateZones.restingHeartRate, unit: "bpm", numberFormatter: .noDecimalPlaces),
        maxHeartRate: HealthVitalData.Quantity(value: heartRateZones.maxHeartRate, unit: "bpm", numberFormatter: .noDecimalPlaces),
        zone1: HealthVitalData.QuantityRange(
          lower: HealthVitalData.Quantity(value: heartRateZones.zone1, unit: "bpm", numberFormatter: .noDecimalPlaces),
          upper: HealthVitalData.Quantity(value: heartRateZones.zone2, unit: "bpm", numberFormatter: .noDecimalPlaces)
        ),
        zone2: HealthVitalData.QuantityRange(
          lower: HealthVitalData.Quantity(value: heartRateZones.zone2, unit: "bpm", numberFormatter: .noDecimalPlaces),
          upper: HealthVitalData.Quantity(value: heartRateZones.zone3, unit: "bpm", numberFormatter: .noDecimalPlaces)
        ),
        zone3: HealthVitalData.QuantityRange(
          lower: HealthVitalData.Quantity(value: heartRateZones.zone3, unit: "bpm", numberFormatter: .noDecimalPlaces),
          upper: HealthVitalData.Quantity(value: heartRateZones.zone4, unit: "bpm", numberFormatter: .noDecimalPlaces)
        ),
        zone4: HealthVitalData.QuantityRange(
          lower: HealthVitalData.Quantity(value: heartRateZones.zone4, unit: "bpm", numberFormatter: .noDecimalPlaces),
          upper: HealthVitalData.Quantity(value: heartRateZones.zone5, unit: "bpm", numberFormatter: .noDecimalPlaces)
        ),
        zone5: HealthVitalData.QuantityRange(
          lower: HealthVitalData.Quantity(value: heartRateZones.zone5, unit: "bpm", numberFormatter: .noDecimalPlaces),
          upper: HealthVitalData.Quantity(value: heartRateZones.maxHeartRate, unit: "bpm", numberFormatter: .noDecimalPlaces)
        )
      ),
      heartRateZoneWorkoutSamples: samples
    )

    return convertToString(value: zones)
  }
}

private extension ChatHealthQueryPerformer {

  func convertToString<T: Encodable>(value: T) -> String {
    do {
      let data = try encoder.encode(value)
      return String(data: data, encoding: .utf8) ?? ""
    } catch {
      return "There was an error querying this data."
    }
  }

  func formattedAverage(
    for quantityType: HKQuantityTypeIdentifier,
    unit: HKUnit,
    dateRange: DateRange
  ) async -> String? {
    let quantity = await HealthStoreFetcher.shared.fetchNutritionalDailyAverage(
      for: quantityType,
      unit: unit,
      dateRange: dateRange
    )
    guard quantity.doubleValue(for: unit) >= 0.001 else { return nil }

    return await quantity.displayString(for: unit)
  }
  
  func fetchReminders(query: SocketMessage.Query) async -> String {
    do {
      let reminderModelActor = ReminderModelActor.standard()
      let reminders = try await reminderModelActor.fetchAllReminders()
      
      let reminderData: [ChatReminderData.Reminder] = reminders.map { reminder in
        let occurrenceData = reminder.occurrences.map { occurrence in
          let monthName = occurrence.monthOfYear != nil ? monthName(for: occurrence.monthOfYear!) : nil
          return ChatReminderData.Occurrence(
            id: occurrence.id,
            cadenceType: occurrence.cadenceType.displayName,
            timeOfDay: formatTimeOfDay(occurrence.timeOfDay),
            daysOfWeek: occurrence.daysOfWeek?.compactMap { weekdayName(for: $0) },
            dayOfMonth: occurrence.dayOfMonth,
            monthOfYear: monthName,
            dayOfYear: occurrence.dayOfYear
          )
        }
        
        let filteredCompletions = reminder.completionRecords.compactMap { completion in
          let startDate = query.startDate
          let endDate = query.endDate
          let completedDate = completion.completedDate
          if startDate <= completedDate && completedDate <= endDate {
            return ChatReminderData.Completion(
              id: completion.id,
              completedDate: completedDate
            )
          }
          return nil
        }
        
        return ChatReminderData.Reminder(
          id: reminder.id,
          title: reminder.title,
          color: reminder.colorHex,
          createdDate: reminder.createdDate,
          modifiedDate: reminder.modifiedDate,
          occurrences: occurrenceData,
          completions: filteredCompletions
        )
      }
      
      let response = ChatReminderData(reminders: reminderData)
      return convertToString(value: response)
    } catch {
      return "There was an error querying reminder data."
    }
  }

  
  private func formatTimeOfDay(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval / 3600)
    let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
    
    let calendar = Calendar.current
    let date = calendar.date(bySettingHour: hours, minute: minutes, second: 0, of: Date()) ?? Date()
    return DateFormatter.justTimeShort.string(from: date)
  }
  
  private func weekdayName(for weekday: Int) -> String? {
    guard weekday >= 1 && weekday <= 7 else { return nil }
    return Calendar.current.weekdaySymbols[weekday - 1]
  }
  
  private func monthName(for month: Int) -> String? {
    guard month >= 1 && month <= 12 else { return nil }
    return Calendar.current.monthSymbols[month - 1]
  }
}

// MARK: - Biological Age Helpers

private extension ChatHealthQueryPerformer {

  @MainActor
  func fetchBioAgeSummary(for metrics: [BiologicalAgeMetric]) async -> HealthVitalData.BioAgeSummary? {
    guard let result = BiologicalAgeViewModel.shared.biologicalAgeResult,
          let contributions = result.metricContributions else { return nil }

    let relevantContributions = contributions
      .filter { metrics.contains($0.metric) }
      .map { contribution in
        HealthVitalData.BioAgeContribution(
          metric: contribution.metric.rawValue,
          category: contribution.metric.category.rawValue,
          value: formatMetricValue(contribution),
          ageDelta: formatAgeDelta(contribution.weightedDelta),
          impact: determineImpact(contribution.weightedDelta)
        )
      }

    guard relevantContributions.isNotEmpty else { return nil }

    return HealthVitalData.BioAgeSummary(
      biologicalAge: result.biologicalAge,
      actualAge: result.actualAge,
      ageDelta: result.ageDelta,
      confidence: result.confidence.displayName,
      lastCalculated: DateFormatter.dateTimeMediumWithTimeZone.string(from: result.lastCalculated),
      relevantContributions: relevantContributions
    )
  }

  func formatMetricValue(_ contribution: MetricContribution) -> String {
    let value = contribution.rawValue
    let formatter = NumberFormatter.oneDecimalPlace

    switch contribution.metric {
    case .vo2Max:
      return "\(formatter.string(for: value) ?? "") ml/kg/min"
    case .restingHeartRate, .heartRateRecovery, .heartRateReserve, .sleepHeartRate:
      return "\(formatter.string(for: value) ?? "") bpm"
    case .hrvTrend:
      return "\(formatter.string(for: value) ?? "")%"
    case .zoneMinutes:
      return "\(NumberFormatter.noDecimalPlaces.string(for: value) ?? "") min"
    case .activityLevel:
      return "\(formatter.string(for: value) ?? "")x"
    case .walkingSpeed, .stairClimbSpeed:
      return "\(formatter.string(for: value) ?? "") m/s"
    case .sleepScore:
      return "\(NumberFormatter.noDecimalPlaces.string(for: value) ?? "")/100"
    case .sleepDurationVariability:
      return "\(formatter.string(for: value) ?? "") hrs"
    case .bedtimeConsistency:
      return "\(NumberFormatter.noDecimalPlaces.string(for: value) ?? "") min"
    case .sleepRespiratoryRate:
      return "\(formatter.string(for: value) ?? "") breaths/min"
    case .bodyFatPercentage:
      return "\(formatter.string(for: value) ?? "")%"
    case .bloodPressure:
      return "\(NumberFormatter.noDecimalPlaces.string(for: value) ?? "") mmHg"
    case .smoking:
      return "\(formatter.string(for: value) ?? "") years since quit"
    case .alcohol:
      return "\(NumberFormatter.noDecimalPlaces.string(for: value) ?? "") drinks/week"
    }
  }

  func formatAgeDelta(_ delta: Double) -> String {
    let formatter = NumberFormatter.oneDecimalPlace
    let sign = delta >= 0 ? "+" : ""
    return "\(sign)\(formatter.string(for: delta) ?? "0") years"
  }

  func determineImpact(_ weightedDelta: Double) -> String {
    if weightedDelta < -0.1 {
      return "positive"
    } else if weightedDelta > 0.1 {
      return "negative"
    } else {
      return "neutral"
    }
  }
}
