//
//  ChatVitalConverter.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import Foundation
import BloomFoundation
import HealthKit
import DataContainer

private extension Int {
  static let maxHealthHistoryDays: Int = 7
}

private extension String {
  static let lastHealthConversionDate: String = "ChatVitalConverter.lastHealthConversionDate"
}

final actor ChatVitalConverter {
  static let shared = ChatVitalConverter()

  @Storage(key: .lastHealthConversionDate, defaultValue: nil) var lastHealthConversionDate: Date?

  private init() { }
}

extension ChatVitalConverter {

  func convertHealthData() async -> ChatHealthData? {
    let startDate = determineSearchStartDate()

    let healthData = await ChatHealthData(
      demographics: generateDemographics(),
      activityLevel: generateActivityLevel(from: startDate),
      bodyComposition: generateBodyComposition(from: startDate),
      bowelMovements: generateBowelMovements(form: startDate),
      exerciseEffectiveness: generateExerciseEffectiveness(from: startDate),
      heartHealth: generateHeartHealth(from: startDate),
      menstrualHealth: generateMenstrualHealth(from: startDate),
      sleep: generateSleep(from: startDate),
      stress: generateStress(from: startDate)
    )

    lastHealthConversionDate = Calendar.current.startOfDay(for: .now)

    return healthData.isEmpty ? nil : healthData
  }

  func resetSyncDate() {
    lastHealthConversionDate = nil
  }
}

private extension ChatVitalConverter {

  var maxHistoricalDate: Date {
    guard let projectedDate = Calendar.current.date(byAdding: .day, value: -.maxHealthHistoryDays, to: .now) else { return .now }

    return Calendar.current.startOfDay(for: projectedDate)
  }

  func determineSearchStartDate() -> Date {
    if let lastDate = lastHealthConversionDate {
      return max(maxHistoricalDate, lastDate)
    }
    return maxHistoricalDate
  }
}

private extension ChatVitalConverter {

  func generateDemographics() async -> ChatHealthData.Demographics {
    let age = await HealthManager.shared.age()
    let sex = await HealthManager.shared.sex().name
    let height = await HealthManager.shared.height()
    let healthGoal = await HealthManager.shared.healthGoal.name

    return ChatHealthData.Demographics(
      age: age,
      sex: sex,
      height: height.chatQuantity(for: .meterUnit(with: .centi)),
      healthGoal: healthGoal
    )
  }

  func generateActivityLevel(from date: Date) async -> ChatHealthData.ActivityLevel? {
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
      ChatHealthData.Sample(date: sample.date, quantity: sample.quantity.chatQuantity(for: unit))
    }
    let activeSamples = activeEnergy.map { sample in
      ChatHealthData.Sample(date: sample.date, quantity: sample.quantity.chatQuantity(for: unit))
    }

    return ChatHealthData.ActivityLevel(
      basalEnergyBurned: basalSamples,
      activeEnergyBurned: activeSamples
    )
  }

  func generateBodyComposition(from date: Date) async -> ChatHealthData.BodyCompostiion? {
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
      ChatHealthData.Sample(
        date: $0.date,
        quantity: $0.quantity.chatQuantity(for: .percent())
      )
    }
    let bodyMassUnit = await HKUnit.gramUnit(with: .kilo).localizedUnit()
    let bodyMassSamples = bodyMass.map {
      ChatHealthData.Sample(
        date: $0.date,
        quantity: $0.quantity.chatQuantity(for: bodyMassUnit)
      )
    }

    return ChatHealthData.BodyCompostiion(
      bodyFatPercentage: bodyFatSamples,
      bodyMass: bodyMassSamples
    )
  }

  func generateBowelMovements(form date: Date) async -> ChatHealthData.BowelMovements? {
    let modelActor = BowelMovementModelActor.standard()
    let dateRange = DateRange.fromDateToNow(date)

    do {
      let bowelMovementSamples = try await modelActor.fetchBowelMovements(dateRange: dateRange)

      let samples = bowelMovementSamples.map {
        ChatHealthData.BowelMovementSample(
          date: $0.date,
          bristolStoolType: $0.bristolStoolType,
          duration: $0.duration.name
        )
      }

      guard samples.isNotEmpty else { return nil }

      return ChatHealthData.BowelMovements(samples: samples)
    } catch {
      print(error)
      return nil
    }
  }

  func generateExerciseEffectiveness(from date: Date) async -> ChatHealthData.ExerciseEffectiveness? {
    guard let heartRateZones = await HealthStoreFetcher.shared.heartRateZones() else {
      return nil
    }

    let dateRange = DateRange.fromDateToNow(date)

    let heartRateReports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)

    guard heartRateReports.isNotEmpty else { return nil }

    let samples = heartRateReports.map {
      ChatHealthData.HeartRateZoneWorkoutSample(
        date: $0.workout.startDate,
        workout: $0.workout.workoutActivityType.name,
        workoutDuration: $0.heartZoneDistribution.totalDuration.chatQuantity(for: .minute()),
        zone1Duration: $0.heartZoneDistribution.zone1.chatQuantity(for: .minute()),
        zone2Duration: $0.heartZoneDistribution.zone2.chatQuantity(for: .minute()),
        zone3Duration: $0.heartZoneDistribution.zone3.chatQuantity(for: .minute()),
        zone4Duration: $0.heartZoneDistribution.zone4.chatQuantity(for: .minute()),
        zone5Duration: $0.heartZoneDistribution.zone5.chatQuantity(for: .minute())
      )
    }

    return ChatHealthData.ExerciseEffectiveness(
      heartRateZones: ChatHealthData.HeartRateZones(
        heartRateReserve: ChatHealthData.Quantity(value: heartRateZones.heartRateReserve, unit: "bpm"),
        restingHeartRate: ChatHealthData.Quantity(value: heartRateZones.restingHeartRate, unit: "bpm"),
        maxHeartRate: ChatHealthData.Quantity(value: heartRateZones.maxHeartRate, unit: "bpm"),
        zone1: ChatHealthData.QuantityRange(
          lower: ChatHealthData.Quantity(value: heartRateZones.zone1, unit: "bpm"),
          upper: ChatHealthData.Quantity(value: heartRateZones.zone2, unit: "bpm")
        ),
        zone2: ChatHealthData.QuantityRange(
          lower: ChatHealthData.Quantity(value: heartRateZones.zone2, unit: "bpm"),
          upper: ChatHealthData.Quantity(value: heartRateZones.zone3, unit: "bpm")
        ),
        zone3: ChatHealthData.QuantityRange(
          lower: ChatHealthData.Quantity(value: heartRateZones.zone3, unit: "bpm"),
          upper: ChatHealthData.Quantity(value: heartRateZones.zone4, unit: "bpm")
        ),
        zone4: ChatHealthData.QuantityRange(
          lower: ChatHealthData.Quantity(value: heartRateZones.zone4, unit: "bpm"),
          upper: ChatHealthData.Quantity(value: heartRateZones.zone5, unit: "bpm")
        ),
        zone5: ChatHealthData.QuantityRange(
          lower: ChatHealthData.Quantity(value: heartRateZones.zone5, unit: "bpm"),
          upper: ChatHealthData.Quantity(value: heartRateZones.maxHeartRate, unit: "bpm")
        )
      ),
      heartRateZoneWorkoutSamples: samples
    )
  }

  func generateHeartHealth(from date: Date) async -> ChatHealthData.HeartHealth? {
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
      ChatHealthData.Sample(date: $0.date, quantity: $0.quantity.chatQuantity(for: .vo2Max()))
    }
    let rhrSamples = rhr.map {
      ChatHealthData.Sample(date: $0.date, quantity: $0.quantity.chatQuantity(for: .bpm(), unitOverride: "bpm"))
    }
    let heartRateRecoverySamples = heartRateRecovery.map {
      ChatHealthData.Sample(date: $0.date, quantity: $0.quantity.chatQuantity(for: .bpm(), unitOverride: "bpm"))
    }

    return ChatHealthData.HeartHealth(
      vo2Max: vo2MaxSamples,
      restingHeartRate: rhrSamples,
      heartRateRecoveryOneMinute: heartRateRecoverySamples
    )
  }

  func generateMenstrualHealth(from date: Date) async -> ChatHealthData.MenstrualHealth? {
    guard let shiftedDate = Calendar.current.date(byAdding: .month, value: -1, to: date) else {
      return nil
    }

    let dateRange = DateRange.fromDateToNow(shiftedDate)

    let cycles = await HealthStoreFetcher.shared.fetchMenstrualFlowSamples(dateRange: dateRange)

    let cycleSamples = cycles.compactMap { (cycle) -> ChatHealthData.MenstrualCycle? in
      guard cycle.startDate > date else { return nil }

      return ChatHealthData.MenstrualCycle(
        startDate: cycle.startDate,
        flowSamples: cycle.samples.map { sample in
          ChatHealthData.MenstrualFlowLevelSample(
            date: sample.startDate,
            flowLevel: sample.menstrualFlowCategory.chatFlowLevel
          )
        }
      )
    }

    guard cycleSamples.isNotEmpty else { return nil }

    return ChatHealthData.MenstrualHealth(cycles: cycleSamples)
  }

  func generateSleep(from date: Date) async -> ChatHealthData.Sleep? {
    let dateRange = DateRange.fromDateToNow(date)

    let sleepAnalyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: dateRange)

    guard sleepAnalyses.isNotEmpty else { return nil }

    let sleepDays = sleepAnalyses.map { sleepAnalysis in
      let respiratoryRateQuantity: ChatHealthData.Quantity?
      let averageRespiratoryRate = sleepAnalysis.respiratoryRate.average(keyPath: \.averageRespiratoryRate)
      if averageRespiratoryRate > 0 {
        respiratoryRateQuantity = ChatHealthData.Quantity(value: averageRespiratoryRate, unit: "breaths / minute")
      } else {
        respiratoryRateQuantity = nil
      }

      let soundLevelQuantity: ChatHealthData.Quantity?
      if sleepAnalysis.averageSoundLevel > 0 {
        soundLevelQuantity = ChatHealthData.Quantity(value: sleepAnalysis.averageSoundLevel, unit: HKUnit.decibelAWeightedSoundPressureLevel().unitString)
      } else {
        soundLevelQuantity = nil
      }

      let wristTempQuantity: ChatHealthData.Quantity?
      if let wristTemp = sleepAnalysis.wristTemperature?.averageWristTemperature, wristTemp > 0 {
        wristTempQuantity = ChatHealthData.Quantity(value: wristTemp, unit: HKUnit.degreeFahrenheit().unitString)
      } else {
        wristTempQuantity = nil
      }

      return ChatHealthData.SleepDay(
        startDate: sleepAnalysis.startDate,
        endDate: sleepAnalysis.endDate,
        deepSleep: sleepAnalysis.hasDetailedSleepCategories ? ChatHealthData.Quantity(value: sleepAnalysis.deepSleepMinutes, unit: "minute") : nil,
        coreSleep: sleepAnalysis.hasDetailedSleepCategories ? ChatHealthData.Quantity(value: sleepAnalysis.coreSleepMinutes, unit: "minute") : nil,
        remSleep: sleepAnalysis.hasDetailedSleepCategories ? ChatHealthData.Quantity(value: sleepAnalysis.remSleepMinutes, unit: "minute") : nil,
        awakeSleep: sleepAnalysis.hasDetailedSleepCategories ? ChatHealthData.Quantity(value: sleepAnalysis.awakeSleepMinutes, unit: "minute") : nil,
        averageHeartRate: sleepAnalysis.averageHeartRate.map { ChatHealthData.Quantity(value: $0, unit: "bpm") },
        averageRespiratoryRate: respiratoryRateQuantity,
        averageDecibelAWeightedEnvironmentalSoundPressureLevel: soundLevelQuantity,
        wristTemperature: wristTempQuantity
      )
    }

    return ChatHealthData.Sleep(sleepDetails: sleepDays)
  }

  func generateStress(from date: Date) async -> ChatHealthData.Stress? {
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
      ChatHealthData.Sample(
        date: $0.date,
        quantity: $0.quantity.chatQuantity(for: .secondUnit(with: .milli))
      )
    }

    var bloodPressureSamples = [ChatHealthData.BloodPressureSample]()
    Calendar.current.iterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
      guard
        let systolicSample = systolic.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }),
        let diastolicSample = diastolic.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
      else {
        return
      }

      bloodPressureSamples.append(
        ChatHealthData.BloodPressureSample(
          date: systolicSample.date,
          systolic: systolicSample.quantity.chatQuantity(for: .millimeterOfMercury()),
          distolic: diastolicSample.quantity.chatQuantity(for: .millimeterOfMercury())
        )
      )
    }

    guard hrvSamples.isNotEmpty || bloodPressureSamples.isNotEmpty else { return nil }

    return ChatHealthData.Stress(
      heartRateVariability: hrvSamples,
      bloodPressureSamples: bloodPressureSamples
    )
  }
}

extension HKQuantity {

  func chatQuantity(for unit: HKUnit, unitOverride: String? = nil) -> ChatHealthData.Quantity {
    ChatHealthData.Quantity(value: doubleValue(for: unit), unit: unitOverride ?? unit.sensibleUnitString)
  }
}

extension MenstrualCycle.MenstrualFlow {
  var chatFlowLevel: ChatHealthData.MenstrualFlowLevelSample.FlowLevel {
    switch self {
    case .unspecified, .none:
      return .none
    case .light:
      return .light
    case .medium:
      return .medium
    case .heavy:
      return .heavy
    }
  }
}
