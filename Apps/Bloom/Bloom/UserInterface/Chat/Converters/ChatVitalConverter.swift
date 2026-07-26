//
//  ChatVitalConverter.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import Foundation
import BloomFoundation
import BloomUI
import HealthKit
import DataContainer
@preconcurrency import CoreHealth
@preconcurrency import CoreNetwork

private extension Int {
  static let maxHealthHistoryDays: Int = 7
}

private extension String {
  static let lastHealthConversionDate: String = "ChatVitalConverter.lastHealthConversionDate"
}

final actor ChatVitalConverter {
  static let shared = ChatVitalConverter()

  private init() { }

  private let foodLogModelActor = FoodItemLogModelActor.standard()
}

extension ChatVitalConverter {

  func convertHealthDataString() async throws -> String {
    let startDate = determineSearchStartDate()
    let enabledCategories = await AIDataSharingSettings.shared.enabledCategories

    guard let healthData = await convertHealthData(from: startDate, enabledCategories: enabledCategories) else { return "" }

    let data = try JSONEncoder.bloomModel.encode(healthData)
    return String(data: data, encoding: .utf8) ?? "{}"
  }

  func convertHealthData(from startDate: Date, enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData? {
    let healthData = await HealthVitalData(
      activityLevel: generateActivityLevel(from: startDate, enabledCategories: enabledCategories),
      bodyComposition: generateBodyComposition(from: startDate, enabledCategories: enabledCategories),
      bowelMovements: generateBowelMovements(form: startDate, enabledCategories: enabledCategories),
      exerciseEffectiveness: generateExerciseEffectiveness(from: startDate, enabledCategories: enabledCategories),
      heartHealth: generateHeartHealth(from: startDate, enabledCategories: enabledCategories),
      menstrualHealth: generateMenstrualHealth(from: startDate, enabledCategories: enabledCategories),
      nutrition: generateNutritionHealth(from: startDate, enabledCategories: enabledCategories),
      sleep: generateSleep(from: startDate, enabledCategories: enabledCategories),
      stress: generateStress(from: startDate, enabledCategories: enabledCategories),
      biologicalAge: generateBiologicalAge(enabledCategories: enabledCategories)
    )

    return healthData.isEmpty ? nil : healthData
  }
}

private extension ChatVitalConverter {

  var maxHistoricalDate: Date {
    guard let projectedDate = Calendar.current.date(byAdding: .day, value: -.maxHealthHistoryDays, to: .now) else { return .now }

    return Calendar.current.startOfDay(for: projectedDate)
  }

  func determineSearchStartDate() -> Date {
    return maxHistoricalDate
  }
}

extension ChatVitalConverter {

  func generateDemographics(enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.UserInfo? {
    // Check if we should send demographics and/or location
    let shouldFetchDemographics = enabledCategories.contains(.demographics)
    let shouldFetchLocation = enabledCategories.contains(.location)

    // If both disabled, return nil (nothing to send)
    guard shouldFetchDemographics || shouldFetchLocation else {
      return nil
    }

    // Conditionally fetch demographics data (only if .demographics enabled)
    let age: Int?
    let sex: String?
    let heightString: String?
    let focus: String?
    let workoutEquipment: [String]
    let userFacts: [ChatUserFactsData.UserFact]

    if shouldFetchDemographics {
      age = await HealthManager.shared.age()
      sex = await HealthManager.shared.sex().name
      let height = await HealthManager.shared.height()
      focus = await HealthManager.shared.focus
      workoutEquipment = Array(await HealthManager.shared.selectedWorkoutEquipment)

      // Fetch user facts
      let userFactModelActor = UserFactModelActor.standard()
      let userFactDTOs = try? await userFactModelActor.fetchAllUserFacts()
      userFacts = userFactDTOs?.map { dto in
        ChatUserFactsData.UserFact(
          id: dto.id,
          fact: dto.fact,
          dateAdded: dto.dateAdded,
          revisitDate: dto.revisitDate
        )
      } ?? []

      heightString = await {
        guard height.doubleValue(for: .meterUnit(with: .centi)) > 0 else { return nil }
        let heightUnit = await HKUnit.meterUnit(with: .centi).localizedUnit()
        return await height.displayString(for: heightUnit, formatter: .oneDecimalPlace)
      }()
    } else {
      // Demographics disabled - nil out all demographic fields
      age = nil
      sex = nil
      heightString = nil
      focus = nil
      workoutEquipment = []
      userFacts = []
    }

    // Conditionally fetch location (independent of demographics)
    let locationString: String?
    if shouldFetchLocation {
      locationString = await LocationManagerViewModel.shared.locationString()
    } else {
      locationString = nil
    }

    return HealthVitalData.UserInfo(
      age: age,
      sex: sex,
      height: heightString,
      focus: focus,
      location: locationString,
      workoutEquipment: workoutEquipment,
      userFacts: userFacts
    )
  }

  func generateDateTime() -> HealthVitalData.DateTime {
    HealthVitalData.DateTime(
      currentDate: DateFormatter.dateTimeMediumWithTimeZone.string(from: .now),
      timeZone: TimeZone.current.identifier
    )
  }

  func generateActivityLevel(from date: Date, enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.ActivityLevel? {
    guard enabledCategories.contains(.physicalActivity) else {
      return nil
    }

    let dateRange = DateRange.fromDateToNow(date)

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

    guard basalEnergy.isNotEmpty || activeEnergy.isNotEmpty else { return nil }

    let basalSamples = basalEnergy.map { sample in
      HealthVitalData.Sample(date: sample.date, quantity: sample.quantity.chatQuantity(for: unit, numberFormatter: .noDecimalPlaces))
    }
    let activeSamples = activeEnergy.map { sample in
      HealthVitalData.Sample(date: sample.date, quantity: sample.quantity.chatQuantity(for: unit, numberFormatter: .noDecimalPlaces))
    }

    return HealthVitalData.ActivityLevel(
      basalEnergyBurned: basalSamples,
      activeEnergyBurned: activeSamples
    )
  }

  func generateBodyComposition(from date: Date, enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.BodyComposition? {
    guard enabledCategories.contains(.bodyMetrics) else {
      return nil
    }

    let dateRange = DateRange.fromDateToNow(date)

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
      return nil
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

    return HealthVitalData.BodyComposition(
      bodyFatPercentage: bodyFatSamples,
      bodyMass: bodyMassSamples
    )
  }

  func generateBowelMovements(form date: Date, enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.BowelMovements? {
    guard enabledCategories.contains(.digestiveHealth) else {
      return nil
    }

    let modelActor = BowelMovementModelActor.standard()
    let dateRange = DateRange.fromDateToNow(date)

    do {
      let bowelMovementSamples = try await modelActor.fetchBowelMovements(dateRange: dateRange)

      let samples = bowelMovementSamples.map {
        HealthVitalData.BowelMovementSample(
          date: $0.date,
          bristolStoolType: $0.bristolStoolType,
          duration: $0.duration.name
        )
      }

      guard samples.isNotEmpty else { return nil }

      return HealthVitalData.BowelMovements(samples: samples)
    } catch {
      print(error)
      return nil
    }
  }

  func generateExerciseEffectiveness(from date: Date, enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.ExerciseEffectiveness? {
    guard enabledCategories.contains(.physicalActivity) else {
      return nil
    }

    guard let heartRateZones = await HealthStoreFetcher.shared.heartRateZones() else {
      return nil
    }

    let dateRange = DateRange.fromDateToNow(date)

    let heartRateReports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)

    guard heartRateReports.isNotEmpty else { return nil }

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

    return HealthVitalData.ExerciseEffectiveness(
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
  }

  func generateHeartHealth(from date: Date, enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.HeartHealth? {
    guard enabledCategories.contains(.bodyMetrics) else {
      return nil
    }

    let dateRange = DateRange.fromDateToNow(date)

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
      return nil
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

    return HealthVitalData.HeartHealth(
      vo2Max: vo2MaxSamples,
      restingHeartRate: rhrSamples,
      heartRateRecoveryOneMinute: heartRateRecoverySamples
    )
  }

  func generateNutritionHealth(from date: Date, enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.Nutrition? {
    guard enabledCategories.contains(.nutrition) else {
      return nil
    }

    let dateRange = DateRange.fromDateToNow(date)

    var logs = [HealthVitalData.FoodLogDay]()

    await Calendar.current.asyncIterate(
      dateRange: dateRange,
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

    let nutritionalAverages = await generateNutritionalAverages(from: date)

    return HealthVitalData.Nutrition(
      nutritionAverages: nutritionalAverages,
      foodLogs: logs
    )
  }

  func generateNutritionalAverages(from date: Date) async -> HealthVitalData.NutritionAverages {
    let dateRange = DateRange.fromDateToNow(date)

    return HealthVitalData.NutritionAverages(
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

  func generateMenstrualHealth(from date: Date, enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.MenstrualHealth? {
    guard enabledCategories.contains(.menstrualHealth) else {
      return nil
    }

    guard let shiftedDate = Calendar.current.date(byAdding: .month, value: -1, to: date) else {
      return nil
    }

    let dateRange = DateRange.fromDateToNow(shiftedDate)

    let cycles = await HealthStoreFetcher.shared.fetchMenstrualFlowSamples(dateRange: dateRange)

    let cycleSamples = cycles.compactMap { (cycle) -> HealthVitalData.MenstrualCycle? in
      guard cycle.startDate > date else { return nil }

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

    guard cycleSamples.isNotEmpty else { return nil }

    return HealthVitalData.MenstrualHealth(cycles: cycleSamples)
  }

  func generateSleep(from date: Date, enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.Sleep? {
    guard enabledCategories.contains(.sleep) else {
      return nil
    }

    let dateRange = DateRange.fromDateToNow(date)

    let sleepAnalyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: dateRange)

    guard sleepAnalyses.isNotEmpty else { return nil }

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

    return HealthVitalData.Sleep(sleepDetails: sleepDays)
  }

  func generateStress(from date: Date, enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.Stress? {
    guard enabledCategories.contains(.mentalWellness) else {
      return nil
    }

    let dateRange = DateRange.fromDateToNow(date)

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

    guard hrvSamples.isNotEmpty || bloodPressureSamples.isNotEmpty else { return nil }

    return HealthVitalData.Stress(
      heartRateVariability: hrvSamples,
      bloodPressureSamples: bloodPressureSamples
    )
  }
}

// MARK: - Biological Age

extension ChatVitalConverter {

  @MainActor
  func generateBiologicalAge(enabledCategories: Set<AIHealthCategory>) async -> HealthVitalData.BioAgeSummary? {
    guard let result = BiologicalAgeViewModel.shared.biologicalAgeResult,
          let contributions = result.metricContributions else { return nil }

    // Filter contributions based on enabled privacy categories
    let filteredContributions = contributions.filter { contribution in
      enabledCategories.contains(privacyCategory(for: contribution.metric))
    }

    guard filteredContributions.isNotEmpty else { return nil }

    let bioAgeContributions = filteredContributions.map { contribution in
      HealthVitalData.BioAgeContribution(
        metric: contribution.metric.rawValue,
        category: contribution.metric.category.rawValue,
        value: formatMetricValue(contribution),
        ageDelta: formatAgeDelta(contribution.weightedDelta),
        impact: determineImpact(contribution.weightedDelta)
      )
    }

    return HealthVitalData.BioAgeSummary(
      biologicalAge: result.biologicalAge,
      actualAge: result.actualAge,
      ageDelta: result.ageDelta,
      confidence: result.confidence.displayName,
      lastCalculated: DateFormatter.dateTimeMediumWithTimeZone.string(from: result.lastCalculated),
      relevantContributions: bioAgeContributions
    )
  }

  private nonisolated func privacyCategory(for metric: BiologicalAgeMetric) -> AIHealthCategory {
    switch metric {
    case .vo2Max, .restingHeartRate, .heartRateRecovery, .heartRateReserve, .bodyFatPercentage:
      return .bodyMetrics
    case .hrvTrend, .bloodPressure:
      return .mentalWellness
    case .zoneMinutes, .activityLevel, .walkingSpeed, .stairClimbSpeed:
      return .physicalActivity
    case .sleepScore, .sleepDurationVariability, .bedtimeConsistency, .sleepHeartRate, .sleepRespiratoryRate:
      return .sleep
    case .smoking, .alcohol:
      return .lifestyle
    @unknown default:
      return .bodyMetrics
    }
  }

  private nonisolated func formatMetricValue(_ contribution: MetricContribution) -> String {
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
    @unknown default:
      return ""
    }
  }

  private nonisolated func formatAgeDelta(_ delta: Double) -> String {
    let formatter = NumberFormatter.oneDecimalPlace
    let sign = delta >= 0 ? "+" : ""
    return "\(sign)\(formatter.string(for: delta) ?? "0") years"
  }

  private nonisolated func determineImpact(_ weightedDelta: Double) -> String {
    if weightedDelta < -0.1 {
      return "positive"
    } else if weightedDelta > 0.1 {
      return "negative"
    } else {
      return "neutral"
    }
  }
}

extension HKQuantity {

  func chatQuantity(for unit: HKUnit, unitOverride: String? = nil, numberFormatter: NumberFormatter) -> HealthVitalData.Quantity {
    HealthVitalData.Quantity(
      value: doubleValue(for: unit),
      unit: unitOverride ?? unit.sensibleUnitString,
      numberFormatter: numberFormatter
    )
  }
}

extension MenstrualCycle.MenstrualFlow {
  var chatFlowLevel: HealthVitalData.MenstrualFlowLevelSample.FlowLevel {
    switch self {
    case .unspecified, .none:
      return .none
    case .light:
      return .light
    case .medium:
      return .medium
    case .heavy:
      return .heavy
    @unknown default:
      return .none
    }
  }
}
