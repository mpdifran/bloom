//
//  HealthStoreFetcher.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation
@preconcurrency import HealthKit
import BloomFoundation
import CoreLocation

private extension TimeInterval {
  static let maxSleepGroupTimeDistance: TimeInterval = 14400 // 4 hours
  static let maxMenstruationTimeGap: TimeInterval = TimeInterval(60 * 60 * 24 * 2) // 2 days
}

public final actor HealthStoreFetcher {
  public static let shared = HealthStoreFetcher()

  private let healthStore = HKHealthStore()
  private var backgroundDeliveryReferenceCounts = [HKObjectType: Int]()

  private init() { }
}

// MARK: Background Delivery

public extension HealthStoreFetcher {

  func enableBackgroundDelivery(
    objectType: HKObjectType,
    frequency: HKUpdateFrequency = .immediate
  ) -> HKBackgroundDeliveryHandle {
    enableBackgroundDelivery(objectTypes: [objectType], frequency: frequency)
  }

  func enableBackgroundDelivery(
    objectTypes: [HKObjectType],
    frequency: HKUpdateFrequency = .immediate
  ) -> HKBackgroundDeliveryHandle {

    for objectType in objectTypes {
//      print("Health Background Delivery Ref Counts: Enabling delivery for \(objectType).")
      // TODO: We should check the existing frequency and make sure we update it only if it's more often.
      healthStore.enableBackgroundDelivery(objectType: objectType, frequency: frequency)
      backgroundDeliveryReferenceCounts[objectType, default: 0] += 1
    }

    return HKBackgroundDeliveryHandle(objectTypes: objectTypes) { [weak self] in
      Task { @Sendable [weak self] in
        await self?.decreaseCount(for: objectTypes)
      }
    }
  }

  private func decreaseCount(for objectTypes: [HKObjectType]) {
    for objectType in objectTypes {
      var refCount = backgroundDeliveryReferenceCounts[objectType, default: 0]

      refCount -= 1

      if refCount <= 0 {
//        print("Health Background Delivery Ref Counts: Disabling delivery for \(objectType).")
        healthStore.disableBackgroundDelivery(for: objectType) { success, error in
          if let error {
            print(error)
          }
        }
      }

      backgroundDeliveryReferenceCounts[objectType] = max(refCount, 0)
    }
  }
}

// MARK: Fetching Data

public extension HealthStoreFetcher {

  func fetchLatestSample(for quantityType: HKQuantityTypeIdentifier) async -> HKQuantitySample? {
    (try? await healthStore.fetchLatestSample(for: quantityType)) as? HKQuantitySample
  }

  func fetchMostRecentSample(for quantityType: HKQuantityTypeIdentifier, dateRange: DateRange) async -> HKQuantitySample? {
    guard let sample = await fetchLatestSample(for: quantityType) else {
      return nil
    }
    
    // Check if the sample date falls within the specified range
    guard dateRange.contains(date: sample.startDate) else { return nil }
    
    return sample
  }

  func fetchTotalQuantity(for quantityType: HKQuantityTypeIdentifier, dateRange: DateRange) async -> HKQuantity? {
    try? await healthStore.fetchQuantity(for: quantityType, dateRange: dateRange, option: .cumulativeSum)
  }

  func fetchCollatedQuantity(
    for quantityType: HKQuantityTypeIdentifier,
    unit: HKUnit,
    interval: DateComponents = DateComponents(day: 1),
    options: HKStatisticsOptions = [.cumulativeSum],
    dateRange: DateRange
  ) async -> [DateQuantitySample] {
    (try? await healthStore.fetchCollatedQuantity(
      quantityTypeID: quantityType,
      unit: unit,
      interval: interval,
      options: options,
      dateRange: dateRange
    )) ?? []
  }

  func fetchAverage(
    for quantityType: HKQuantityTypeIdentifier,
    unit: HKUnit,
    divisor: Double? = nil,
    dateRange: DateRange
  ) async -> HKQuantity {
    let totalSum = await fetchTotalQuantity(for: quantityType, dateRange: dateRange)
    let resolvedDivisor = divisor ?? Double(dateRange.numberOfDaysInclusive)
    let average = (totalSum?.doubleValue(for: unit) ?? 0) / resolvedDivisor

    return HKQuantity(unit: unit, doubleValue: average)
  }

  func fetchCollatedAverage(
    quantityType: HKQuantityTypeIdentifier,
    unit: HKUnit,
    interval: DateComponents = DateComponents(day: 1),
    dateRange: DateRange
  ) async -> [DateQuantitySample] {
    return (try? await healthStore.fetchAverageStatistics(
      quantityTypeID: quantityType,
      unit: unit,
      interval: interval,
      dateRange: dateRange
    )) ?? []
  }

  func fetchNutritionalDailyAverage(
    for quantityType: HKQuantityTypeIdentifier,
    unit: HKUnit,
    dateRange: DateRange
  ) async -> HKQuantity {
    let quantities = (try? await healthStore.fetchCollatedQuantity(
      quantityTypeID: quantityType,
      unit: unit,
      dateRange: dateRange
    )) ?? []

    let trimmedQuantities = quantities.trim(where: { $0.quantity.doubleValue(for: unit) == 0 })
    let average = trimmedQuantities.map({ $0.quantity.doubleValue(for: unit) }).average(keyPath: \.self)

    return HKQuantity(unit: unit, doubleValue: average)
  }

  func fetchDailyAverage(
    for quantityType: HKQuantityTypeIdentifier,
    unit: HKUnit,
    dateRange: DateRange,
    option: HKStatisticsOptions = .discreteAverage
  ) async -> HKQuantity? {
    try? await healthStore.fetchDailyAverageQuantity(
      for: quantityType,
      unit: unit,
      dateRange: dateRange,
      option: option
    )
  }

  func fetchSamples(
    for sampleType: HKSampleType,
    dateRange: DateRange,
    writtenByApp: Bool = false
  ) async throws -> [HKSample] {
    // Source is the current app.
    let predicateFromApp = HKQuery.predicateForObjects(from: HKSource.default())
    return try await healthStore.fetchSamples(
      for: sampleType,
      dateRange: dateRange,
      additionalPredicates: writtenByApp ? [predicateFromApp] : []
    )
  }

  func fetchNetEnergy(dateRange: DateRange) async -> [DateQuantitySample] {

    let basal = try? await healthStore.fetchCollatedQuantity(
      quantityTypeID: .basalEnergyBurned,
      unit: .largeCalorie(),
      dateRange: dateRange
    )

    let active = try? await healthStore.fetchCollatedQuantity(
      quantityTypeID: .activeEnergyBurned,
      unit: .largeCalorie(),
      dateRange: dateRange
    )

    let dietary = try? await healthStore.fetchCollatedQuantity(
      quantityTypeID: .dietaryEnergyConsumed,
      unit: .largeCalorie(),
      dateRange: dateRange
    )

    return basal?.compactMap { basalSample in
      guard
        let activeEnergy = active?.first(where: { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) })?.quantity,
        let dietaryEnergy = dietary?.first(where: { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) })?.quantity,
        dietaryEnergy.doubleValue(for: .largeCalorie()) >= 1 
      else {
        return nil
      }

      let totalBurnedEnergy = basalSample.quantity.sum(activeEnergy, unit: .largeCalorie())
      let netEnergy = dietaryEnergy.subtract(totalBurnedEnergy, unit: .largeCalorie())

      return DateQuantitySample(
        date: basalSample.date,
        quantity: netEnergy
      )
    } ?? []
  }

  func fetchWorkouts(activityType: HKWorkoutActivityType? = nil, dateRange: DateRange, limit: Int? = nil) async -> [HKWorkout] {
    (try? await healthStore.fetchWorkouts(activityType: activityType, dateRange: dateRange, limit: limit)) ?? []
  }

  func fetchWorkouts(activityTypes: [HKWorkoutActivityType], dateRange: DateRange, limit: Int? = nil) async -> [HKWorkout] {
    (try? await healthStore.fetchWorkouts(activityTypes: activityTypes, dateRange: dateRange, limit: limit)) ?? []
  }

  func fetchCollatedWorkouts(
    activityType: HKWorkoutActivityType,
    dateRange: DateRange
  ) async -> [DateCollatedWorkouts] {
    await fetchCollatedWorkouts(activityTypes: [activityType], dateRange: dateRange)
  }

  func fetchCollatedWorkouts(
    activityTypes: [HKWorkoutActivityType] = [],
    dateRange: DateRange
  ) async -> [DateCollatedWorkouts] {
    (try? await healthStore.fetchCollatedWorkouts(
      activityTypes: activityTypes,
      dateRange: dateRange
    )) ?? []
  }

  func fetchWorkoutSummations(dateRange: DateRange) async -> [WorkoutSummation] {
    (try? await healthStore.fetchWorkoutSummation(dateRange: dateRange)) ?? []
  }

  func fetchTotalMeditationMinutes(dateRange: DateRange) async -> HKQuantity {
    let samples = (try? await healthStore.fetchSamples(for: HKCategoryType(.mindfulSession), dateRange: dateRange)) ?? []

    let meditationMinutes = samples.reduce(0) { (total, sample) -> Double in
      total + sample.timeInterval / 60
    }
    return HKQuantity(unit: .minute(), doubleValue: meditationMinutes)
  }

  func fetchCollatedMeditationMinutes(
    dateRange: DateRange
  ) async -> [DateQuantitySample] {
    let samples = (try? await healthStore.fetchSamples(for: HKCategoryType(.mindfulSession), dateRange: dateRange)) ?? []

    var result = [DateQuantitySample]()

    Calendar.current.iterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
      let currentDateSamples = samples.filter({ Calendar.current.isDate($0.startDate, inSameDayAs: date) })

      let sum = currentDateSamples.reduce(0) { (total, sample) -> Double in
        total + (sample.timeInterval / 60)
      }

      let sample = DateQuantitySample(date: date, quantity: HKQuantity(unit: .minute(), doubleValue: sum))
      result.append(sample)
    }

    return result
  }

  func fetchMenstrualFlowSamples(dateRange: DateRange) async -> [MenstrualCycle] {
    let samples = (try? await healthStore.fetchSamples(for: HKCategoryType(.menstrualFlow), dateRange: dateRange)) ?? []
    let categorySamples = samples as? [HKCategorySample] ?? []

    return groupMenstrualCycles(from: categorySamples)
  }

  func fetchDietaryNutritionPercentage(
    quantityTypeID: HKQuantityTypeIdentifier,
    caloriesPerGram: Double,
    dateRange: DateRange
  ) async -> Double {
    do {
      let quantity = try await healthStore.fetchQuantity(
        for: quantityTypeID,
        dateRange: dateRange,
        option: .cumulativeSum
      )

      let dietaryEnergy = try await healthStore.fetchQuantity(
        for: .dietaryEnergyConsumed,
        dateRange: dateRange,
        option: .cumulativeSum
      )

      return (quantity.doubleValue(for: .gram()) * caloriesPerGram) / dietaryEnergy.doubleValue(for: .largeCalorie())
    } catch {
      print(error)
    }
    return 0
  }

  func fetchWorkoutHeartRateReport(workout: HKWorkout) async -> WorkoutHeartRateReport? {
    guard let targetHeartRateZones = await heartRateZones() else { return nil }

    guard let heartRateSamples = try? await healthStore.fetchSamples(
      for: HKQuantityType(.heartRate),
      dateRange: workout.dateRange
    ) as? [HKQuantitySample] else {
      return nil
    }

    guard heartRateSamples.isNotEmpty else { return nil }

    return WorkoutHeartRateReport(
      workout: workout,
      heartRateSamples: heartRateSamples,
      heartRateZones: targetHeartRateZones
    )
  }

  func fetchWorkoutHeartRateReports(dateRange: DateRange) async -> [WorkoutHeartRateReport] {
    let workouts = (try? await healthStore.fetchWorkouts(dateRange: dateRange)) ?? []
    var reports = [WorkoutHeartRateReport]()

    for workout in workouts {
      guard let report = await fetchWorkoutHeartRateReport(workout: workout) else { continue }

      reports.append(report)
    }

    return reports
  }

  func fetchCollatedWorkoutHeartRateReports(
    dateRange: DateRange
  ) async -> [DateCollatedWorkoutHeartRateReport] {
    let collatedWorkouts = await fetchCollatedWorkouts(dateRange: dateRange)

    var collatedReports = [DateCollatedWorkoutHeartRateReport]()

    for collatedWorkout in collatedWorkouts {
      var reports = [WorkoutHeartRateReport]()

      for workout in collatedWorkout.workouts {
        guard let report = await fetchWorkoutHeartRateReport(workout: workout) else { continue }

        reports.append(report)
      }

      let collatedReport = DateCollatedWorkoutHeartRateReport(date: collatedWorkout.date, reports: reports)
      collatedReports.append(collatedReport)
    }

    return collatedReports
  }

  func fetchWorkoutRoutes(for workout: HKWorkout) -> AsyncStream<[WorkoutRoute]> {
    healthStore.fetchWorkoutRoutes(for: workout)
  }

  /// Checks if a workout has an associated route (GPS data), indicating an outdoor workout.
  func workoutHasRoute(_ workout: HKWorkout) async -> Bool {
    await withCheckedContinuation { continuation in
      let routeType = HKSeriesType.workoutRoute()
      let predicate = HKQuery.predicateForObjects(from: workout)

      let query = HKSampleQuery(
        sampleType: routeType,
        predicate: predicate,
        limit: 1,
        sortDescriptors: nil
      ) { _, samples, _ in
        continuation.resume(returning: samples?.isEmpty == false)
      }

      healthStore.execute(query)
    }
  }

  func fetchSleepAnalysis(dateRange: DateRange) async -> [SleepAnalysis] {
    let samples = (try? await healthStore.fetchSamples(
      for: HKCategoryType(.sleepAnalysis),
      dateRange: dateRange
    )) ?? []
    return await processSleepAnalysis(samples: samples)
  }

  func fetchSleepAnalysis(for date: Date) async -> SleepAnalysis? {
    let endDate = Calendar.current.endOfDay(for: date)
    let sleepAnalyses = await fetchSleepAnalysis(dateRange: .trailingDays(from: endDate, numberOfDays: 3))
    return sleepAnalyses.first(where: { Calendar.current.isDate($0.endDate, inSameDayAs: date) })
  }
}

// MARK: Grouping Algorithms

extension HealthStoreFetcher {

  func groupMenstrualCycles(from samples: [HKCategorySample]) -> [MenstrualCycle] {
    var cycles = [MenstrualCycle]()
    var currentCycleSamples = [HKCategorySample]()

    for sample in samples {
      if let lastSample = currentCycleSamples.last {
        let timeGap = sample.startDate.timeIntervalSince(lastSample.endDate)

        // If the gap is larger than the threshold
        if timeGap > .maxMenstruationTimeGap {
          // Close out the current cycle and start a new one
          let beginningOfCycleStartDate = currentCycleSamples.first(where: { $0.menstrualFlowCategory.marksBeginningOfCycle })?.startDate
          let cycleStartDate = beginningOfCycleStartDate ?? currentCycleSamples.first?.startDate

          if let cycleStartDate = cycleStartDate {
            let cycle = MenstrualCycle(
              startDate: cycleStartDate,
              samples: currentCycleSamples
            )
            cycles.append(cycle)
          }

          currentCycleSamples = [sample]
        } else {
          currentCycleSamples.append(sample)
        }
      } else {
        // First sample in a new cycle
        currentCycleSamples.append(sample)
      }
    }

    // Append the last cycle
    let beginningOfCycleStartDate = currentCycleSamples.first(where: { $0.menstrualFlowCategory.marksBeginningOfCycle })?.startDate
    let cycleStartDate = beginningOfCycleStartDate ?? currentCycleSamples.first?.startDate

    if let cycleStartDate = cycleStartDate, !currentCycleSamples.isEmpty {
      let cycle = MenstrualCycle(startDate: cycleStartDate, samples: currentCycleSamples)
      cycles.append(cycle)
    }

    return cycles
  }

  func processSleepAnalysis(samples: [HKSample]) async -> [SleepAnalysis] {
    let samples = samples as? [HKCategorySample] ?? []

    var groupedSamples = [[HKCategorySample]]()
    var currentGroup: [HKCategorySample] = []

    for sample in samples {
      if let lastSample = currentGroup.last {
        let interval = sample.startDate.timeIntervalSince(lastSample.endDate)
        if interval <= .maxSleepGroupTimeDistance {
          currentGroup.append(sample)
        } else {
          groupedSamples.append(currentGroup)
          currentGroup = [sample]
        }
      } else {
        currentGroup.append(sample)
      }
    }
    if !currentGroup.isEmpty {
      groupedSamples.append(currentGroup)
    }

    var sleepAnalysis = [SleepAnalysis]()
    for sampleGroup in groupedSamples {
      var hasDetailedSleepCategories = false
      var deepSleepTime: Double = 0
      var coreSleepTime: Double = 0
      var remSleepTime: Double = 0
      var awakeSleepTime: Double = 0

      for sample in sampleGroup {
        switch sample.sleepCategory {
        case .asleepUnspecified, .asleep:
          break
        case .awake:
          awakeSleepTime += sample.timeInterval
          hasDetailedSleepCategories = true
        case .asleepCore:
          coreSleepTime += sample.timeInterval
          hasDetailedSleepCategories = true
        case .asleepDeep:
          deepSleepTime += sample.timeInterval
          hasDetailedSleepCategories = true
        case .asleepREM:
          remSleepTime += sample.timeInterval
          hasDetailedSleepCategories = true
        case .inBed, .none:
          break
        @unknown default:
          break
        }
      }

      let startDate = sampleGroup.reduce(Date.distantFuture) { partialResult, sample in
        switch sample.sleepCategory {
        case .awake, .inBed, .none:
          return partialResult // We don't want to count these as the start and end of sleep.
        default:
          break
        }

        if sample.startDate < partialResult {
          return sample.startDate
        }
        return partialResult
      }

      let endDate = sampleGroup.reduce(Date.distantPast) { partialResult, sample in
        switch sample.sleepCategory {
        case .awake, .inBed, .none:
          return partialResult // We don't want to count these as the start and end of sleep.
        default:
          break
        }

        if sample.endDate > partialResult {
          return sample.endDate
        }
        return partialResult
      }

      guard startDate < endDate else { continue }

      let timePeriod: Int = 30 // minutes
      let dateRange = DateRange(startDate, endDate)

      // Sound levels
      var soundLevelDataPoints = [SleepAnalysis.SoundLevelDataPoint]()
      do {
        let samples = try await healthStore.fetchAverageStatistics(
          quantityTypeID: .environmentalAudioExposure,
          unit: .decibelAWeightedSoundPressureLevel(),
          interval: DateComponents(minute: timePeriod),
          dateRange: dateRange
        )

        for sample in samples {
          let dataPoint = SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: sample.quantity.doubleValue(for: .decibelAWeightedSoundPressureLevel()),
            startDate: sample.date,
            timeRangeSeconds: TimeInterval(timePeriod * 60)
          )
          soundLevelDataPoints.append(dataPoint)
        }
      } catch {
        print(error)
      }

      // Heart rate
      var heartRateDataPoints = [SleepAnalysis.HeartRateDataPoint]()
      do {
        let samples = try await healthStore.fetchAverageStatistics(
          quantityTypeID: .heartRate,
          unit: .bpm(),
          interval: DateComponents(minute: timePeriod),
          dateRange: dateRange
        )

        for sample in samples {
          let dataPoint = SleepAnalysis.HeartRateDataPoint(
            averageHeartRate: sample.quantity.doubleValue(for: .bpm()),
            startDate: sample.date,
            timeRangeSeconds: TimeInterval(timePeriod * 60)
          )
          heartRateDataPoints.append(dataPoint)
        }
      } catch {
        print(error)
      }

      // Respiratory Rate
      var respiratoryRateDataPoints = [SleepAnalysis.RespiratoryRateDataPoint]()
      do {
        let samples = try await healthStore.fetchAverageStatistics(
          quantityTypeID: .respiratoryRate,
          unit: .breathsPerMinute(),
          interval: DateComponents(minute: timePeriod),
          dateRange: dateRange
        )

        for sample in samples {
          let dataPoint = SleepAnalysis.RespiratoryRateDataPoint(
            averageRespiratoryRate: sample.quantity.doubleValue(for: .breathsPerMinute()),
            startDate: sample.date,
            timeRangeSeconds: TimeInterval(timePeriod * 60)
          )
          respiratoryRateDataPoints.append(dataPoint)
        }
      } catch {
        print(error)
      }

      // Wrist Temperature
      var wristTemperatureDataPoint: SleepAnalysis.WristTemperatureDataPoint?
      do {
        if let shiftedStart = Calendar.current.date(byAdding: .minute, value: -30, to: startDate),
           let shiftedEnd = Calendar.current.date(byAdding: .minute, value: 30, to: endDate)
        {
          // Fetch baseline (trailing 7-day average)
          let baselineTemp = try? await healthStore.fetchQuantity(
            for: .appleSleepingWristTemperature,
            dateRange: .trailingDays(from: startDate, numberOfDays: 7),
            option: .discreteAverage
          ).doubleValue(for: .degreeFahrenheit())

          let dateRange = DateRange(shiftedStart, shiftedEnd)
          let samples = try await healthStore.fetchSamples(
            for: HKQuantityType(.appleSleepingWristTemperature),
            dateRange: dateRange
          ) as? [HKQuantitySample] ?? []

          for sample in samples {
            let dataPoint = SleepAnalysis.WristTemperatureDataPoint(
              averageWristTemperature: sample.quantity.doubleValue(for: .degreeFahrenheit()),
              baselineWristTemperature: baselineTemp,
              startDate: sample.startDate,
              timeRangeSeconds: sample.timeInterval
            )
            wristTemperatureDataPoint = dataPoint
          }
        }
      } catch {
        print(error)
      }

      let averageRestingHeartRate = (try? await healthStore.fetchQuantity(
        for: .restingHeartRate,
        dateRange: .trailingDays(from: startDate, numberOfDays: 7),
        option: .discreteAverage
      ))?.doubleValue(for: .bpm())

      let analysis = SleepAnalysis(
        startDate: startDate,
        endDate: endDate,
        hasDetailedSleepCategories: hasDetailedSleepCategories,
        deepSleepMinutes: deepSleepTime / 60,
        coreSleepMinutes: coreSleepTime / 60,
        remSleepMinutes: remSleepTime / 60,
        awakeSleepMinutes: awakeSleepTime / 60,
        averageRestingHeartRate: averageRestingHeartRate,
        environmentalSoundLevels: soundLevelDataPoints,
        heartRate: heartRateDataPoints,
        respiratoryRate: respiratoryRateDataPoints,
        wristTemperature: wristTemperatureDataPoint
      )
      sleepAnalysis.append(analysis)
    }

    return sleepAnalysis
  }
}

// MARK: Vitals

public extension HealthStoreFetcher {

  func fetchActivityLevelSummary() async -> ActivityLevelSummary {
    let thisMonth = await fetchActivityLevelSummaryDetails(dateRange: .trailingMonthsFromNow(1))

    return ActivityLevelSummary(details: thisMonth)
  }

  func fetchActivityLevelSummaryDetails(dateRange: DateRange) async -> ActivityLevelSummary.Details {
    let unit = HKUnit.largeCalorie()
    let basal = (try? await healthStore.fetchCollatedQuantity(
      quantityTypeID: .basalEnergyBurned,
      unit: unit,
      dateRange: dateRange
    )) ?? []

    let active = (try? await healthStore.fetchCollatedQuantity(
      quantityTypeID: .activeEnergyBurned,
      unit: unit,
      dateRange: dateRange
    )) ?? []

    let ratios = calculateRatios(basalEnergy: basal, activeEnergy: active)

    return ActivityLevelSummary.Details(
      averageBasalEnergyBurned: basal.map({ $0.quantity.doubleValue(for: unit) }).average(keyPath: \.self),
      averageActiveEnergyBurned: active.map({ $0.quantity.doubleValue(for: unit) }).average(keyPath: \.self),
      energyRatioSamples: ratios
    )
  }

  func calculateRatios(basalEnergy: [DateQuantitySample], activeEnergy: [DateQuantitySample]) -> [DateValueSample] {
    var samples = [DateValueSample]()
    for basalSample in basalEnergy {
      guard let activeSample = activeEnergy.first(where: { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) }) else {
        continue
      }

      let unit = HKUnit.largeCalorie()

      guard basalSample.quantity.doubleValue(for: unit) > 0 else {
        samples.append(DateValueSample(date: basalSample.date, value: 1))
        continue
      }

      let sum = activeSample.quantity.doubleValue(for: unit) + basalSample.quantity.doubleValue(for: unit)
      let ratio = sum / basalSample.quantity.doubleValue(for: unit)

      samples.append(DateValueSample(date: basalSample.date, value: ratio))
    }
    return samples
  }

  func fetchStressMonthlySummary(trailingMonthAnalyses: [SleepAnalysis]) async -> StressMonthlySummary? {

    let thisMonth = await fetchStressMonthlySummaryDetails(
      dateRange: .trailingMonthsFromNow(1),
      sleepAnalyses: trailingMonthAnalyses
    )
    let lastMonthAverageSystolic = (try? await healthStore.fetchQuantity(
      for: .bloodPressureSystolic,
      dateRange: .trailingMonthsFromMonthsFromNow(monthsFromNow: 1, numberOfMonths: 1)
    ))
    let lastMonthAverageDiastolic = (try? await healthStore.fetchQuantity(
      for: .bloodPressureDiastolic,
      dateRange: .trailingMonthsFromMonthsFromNow(monthsFromNow: 1, numberOfMonths: 1)
    ))

    return StressMonthlySummary(
      details: thisMonth,
      lastMonthAverageSystolic: lastMonthAverageSystolic?.doubleValue(for: .millimeterOfMercury()),
      lastMonthAverageDiastolic: lastMonthAverageDiastolic?.doubleValue(for: .millimeterOfMercury())
    )
  }

  func fetchStressMonthlySummaryDetails(dateRange: DateRange, sleepAnalyses: [SleepAnalysis]) async -> StressMonthlySummary.Details {
    let twoMonthDateRange = DateRange.trailingMonths(from: dateRange.end, numberOfMonths: 2)

    let hrv = await fetchCollatedAverage(
      quantityType: .heartRateVariabilitySDNN,
      unit: .secondUnit(with: .milli),
      dateRange: dateRange
    )

    let hrv2Months = await fetchCollatedAverage(
      quantityType: .heartRateVariabilitySDNN,
      unit: .secondUnit(with: .milli),
      dateRange: twoMonthDateRange
    )

    let systolic = await fetchCollatedAverage(
      quantityType: .bloodPressureSystolic,
      unit: .millimeterOfMercury(),
      dateRange: dateRange
    )

    let systolic2Months = await fetchCollatedAverage(
      quantityType: .bloodPressureSystolic,
      unit: .millimeterOfMercury(),
      dateRange: twoMonthDateRange
    )

    let diastolic = await fetchCollatedAverage(
      quantityType: .bloodPressureDiastolic,
      unit: .millimeterOfMercury(),
      dateRange: dateRange
    )

    let diastolic2Months = await fetchCollatedAverage(
      quantityType: .bloodPressureDiastolic,
      unit: .millimeterOfMercury(),
      dateRange: twoMonthDateRange
    )

    return StressMonthlySummary.Details(
      dateRange: dateRange,
      heartRateVariability: hrv,
      twoMonthsHeartRateVariability: hrv2Months,
      bloodPressureSystolic: systolic,
      twoMonthsBloodPressureSystolic: systolic2Months,
      bloodPressureDiastolic: diastolic,
      twoMonthsBloodPressureDiastolic: diastolic2Months,
      sleepAnalyses: sleepAnalyses
    )
  }

  func fetchNutritionMonthlySummary() async -> NutritionMonthlySummary? {
    let thisMonth = await fetchNutritionMonthlySummaryDetails(
      dateRange: .trailingMonthsFromNow(1)
    )

    return NutritionMonthlySummary(details: thisMonth)
  }

  func fetchNutritionMonthlySummaryDetails(dateRange: DateRange) async -> NutritionMonthlySummary.Details {
    let basalEnergyBurned = try? await healthStore.fetchDailyAverageQuantity(
      for: .basalEnergyBurned,
      unit: .largeCalorie(),
      dateRange: dateRange,
      option: .cumulativeSum
    )

    let activeEnergyBurned = try? await healthStore.fetchDailyAverageQuantity(
      for: .activeEnergyBurned,
      unit: .largeCalorie(),
      dateRange: dateRange,
      option: .cumulativeSum
    )

    let dietaryEnergy = await fetchNutritionalDailyAverage(for: .dietaryEnergyConsumed, unit: .largeCalorie(), dateRange: dateRange)
    let protein = await fetchNutritionalDailyAverage(for: .dietaryProtein, unit: .gram(), dateRange: dateRange)
    let carbohydrates = await fetchNutritionalDailyAverage(for: .dietaryCarbohydrates, unit: .gram(), dateRange: dateRange)
    let fat = await fetchNutritionalDailyAverage(for: .dietaryFatTotal, unit: .gram(), dateRange: dateRange)
    let vitaminA = await fetchNutritionalDailyAverage(for: .dietaryVitaminA, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let vitaminB6 = await fetchNutritionalDailyAverage(for: .dietaryVitaminB6, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let vitaminB12 = await fetchNutritionalDailyAverage(for: .dietaryVitaminB12, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let vitaminC = await fetchNutritionalDailyAverage(for: .dietaryVitaminC, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let vitaminD = await fetchNutritionalDailyAverage(for: .dietaryVitaminD, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let vitaminE = await fetchNutritionalDailyAverage(for: .dietaryVitaminE, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let calcium = await fetchNutritionalDailyAverage(for: .dietaryCalcium, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let iron = await fetchNutritionalDailyAverage(for: .dietaryIron, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let magnesium = await fetchNutritionalDailyAverage(for: .dietaryMagnesium, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let potassium = await fetchNutritionalDailyAverage(for: .dietaryPotassium, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let sodium = await fetchNutritionalDailyAverage(for: .dietarySodium, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let zinc = await fetchNutritionalDailyAverage(for: .dietaryZinc, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let cholesterol = await fetchNutritionalDailyAverage(for: .dietaryCholesterol, unit: .gramUnit(with: .milli), dateRange: dateRange)
    let fiber = await fetchNutritionalDailyAverage(for: .dietaryFiber, unit: .gram(), dateRange: dateRange)
    let sugar = await fetchNutritionalDailyAverage(for: .dietarySugar, unit: .gram(), dateRange: dateRange)

    let collatedDietaryEnergy = await fetchCollatedQuantity(
      for: .dietaryEnergyConsumed,
      unit: .largeCalorie(),
      dateRange: dateRange
    )
    let dietaryEnergyCountAboveZero = collatedDietaryEnergy.count(where: { $0.quantity.doubleValue(for: .largeCalorie()) > 0 })

    let collatedProtein = await fetchCollatedQuantity(
      for: .dietaryProtein,
      unit: .gram(),
      dateRange: dateRange
    )
    let proteinCountAboveZero = collatedProtein.count(where: { $0.quantity.doubleValue(for: .gram()) > 0 })

    return NutritionMonthlySummary.Details(
      numberOfNutritionLogDays: dietaryEnergyCountAboveZero,
      numberOfProteinLogDays: proteinCountAboveZero,
      basalEnergyBurned: basalEnergyBurned,
      activeEnergyBurned: activeEnergyBurned,
      dietaryEnergy: dietaryEnergy,
      averageProtein: protein,
      averageCarbohydrates: carbohydrates,
      averageFat: fat,
      averageVitaminA: vitaminA,
      averageVitaminB6: vitaminB6,
      averageVitaminB12: vitaminB12,
      averageVitaminC: vitaminC,
      averageVitaminD: vitaminD,
      averageVitaminE: vitaminE,
      averageCalcium: calcium,
      averageIron: iron,
      averageMagnesium: magnesium,
      averagePotassium: potassium,
      averageSodium: sodium,
      averageZinc: zinc,
      averageCholesterol: cholesterol,
      averageFiber: fiber,
      averageSugar: sugar
    )
  }

  func fetchHeartHealthSummary() async -> HeartHealthMonthlySummary {
    let details = await fetchHeartHealthDetails(
      dateRange: .trailingMonthsFromNow(1)
    )
    let lastMonthDetails = await fetchHeartHealthDetails(
      dateRange: .trailingMonthsFromMonthsFromNow(
        monthsFromNow: 1,
        numberOfMonths: 1
      )
    )

    return HeartHealthMonthlySummary(details: details, lastMonthDetails: lastMonthDetails)
  }

  func fetchHeartHealthDetails(dateRange: DateRange) async -> HeartHealthMonthlySummary.Details {
    let vo2Max = try? await healthStore.fetchDailyAverageQuantity(
      for: .vo2Max,
      unit: .vo2Max(),
      dateRange: dateRange
    )

    let rhr = try? await healthStore.fetchDailyAverageQuantity(
      for: .restingHeartRate,
      unit: .bpm(),
      dateRange: dateRange
    )

    let heartRateRecovery = try? await healthStore.fetchDailyAverageQuantity(
      for: .heartRateRecoveryOneMinute,
      unit: .bpm(),
      dateRange: dateRange
    )

    return HeartHealthMonthlySummary.Details(
      averageVO2Max: vo2Max,
      averageHeartRateRecovery: heartRateRecovery,
      averageRestingHeartRate: rhr
    )
  }

  func fetchBodyCompositionSummary() async -> BodyCompositionMonthlySummary {
    let thisMonth = await fetchBodyCompositionSummaryDetails(dateRange: .trailingMonthsFromNow(1))
    let lastMonth = await fetchBodyCompositionSummaryDetails(
      dateRange: .trailingMonthsFromMonthsFromNow(
        monthsFromNow: 1,
        numberOfMonths: 1
      )
    )
    return BodyCompositionMonthlySummary(details: thisMonth, lastMonthDetails: lastMonth)
  }

  func fetchBodyCompositionSummaryDetails(dateRange: DateRange) async -> BodyCompositionMonthlySummary.Details {
    let bodyFatPercentage = try? await healthStore.fetchQuantity(for: .bodyFatPercentage, dateRange: dateRange)
    let goalBodyFatPercentage = HealthGoalProvider.shared.goalBodyFatPercentage()
    let bodyMass = try? await healthStore.fetchQuantity(for: .bodyMass, dateRange: dateRange)

    return BodyCompositionMonthlySummary.Details(
      bodyFatPercentage: bodyFatPercentage,
      goalBodyFatPercentage: goalBodyFatPercentage,
      averageBodyMass: bodyMass
    )
  }

  func fetchExerciseEffectivenessSummary() async -> ExerciseEffectivenessMonthlySummary? {
    guard let targetHeartRateZones = await heartRateZones() else { return nil }

    let thisMonth = await fetchExerciseEffectivenessDetails(
      heartRateZones: targetHeartRateZones,
      dateRange: .trailingMonthsFromNow(1)
    )

    return ExerciseEffectivenessMonthlySummary(details: thisMonth)
  }

  func fetchExerciseEffectivenessDetails(
    heartRateZones: HeartRateZones,
    dateRange: DateRange
  ) async -> ExerciseEffectivenessMonthlySummary.Details {
    let workoutReports = await fetchWorkoutHeartRateReports(dateRange: dateRange)
    return ExerciseEffectivenessMonthlySummary.Details(
      heartRateZones: heartRateZones,
      workoutReports: workoutReports
    )
  }

  func fetchSleepVitalSummary(trailingMonthAnalyses: [SleepAnalysis]) async -> SleepVitalsMonthlySummary {
    let thisMonth = fetchSleepVitalSummaryDetails(sleepAnalyses: trailingMonthAnalyses)

    return SleepVitalsMonthlySummary(
      details: thisMonth
    )
  }

  func fetchSleepVitalSummaryDetails(sleepAnalyses: [SleepAnalysis]) -> SleepVitalsMonthlySummary.Details {
    if sleepAnalyses.isEmpty {
      return SleepVitalsMonthlySummary.Details(
        averageREMSleepPercent: nil,
        averageCoreSleepPercent: nil,
        averageDeepSleepPercent: nil,
        averageAwakeSleepPercent: nil,
        averageSleepLength: nil,
        averageSleepScore: nil
      )
    }

    return SleepVitalsMonthlySummary.Details(
      averageREMSleepPercent: sleepAnalyses.average(keyPath: \.remSleepPercent),
      averageCoreSleepPercent: sleepAnalyses.average(keyPath: \.coreSleepPercent),
      averageDeepSleepPercent: sleepAnalyses.average(keyPath: \.deepSleepPercent),
      averageAwakeSleepPercent: sleepAnalyses.average(keyPath: \.awakeSleepPercent),
      averageSleepLength: sleepAnalyses.average(keyPath: \.overallMinutes),
      averageSleepScore: sleepAnalyses.average(keyPath: \.overallScoreDouble)
    )
  }

  func fetchMenstrualSummary() async -> MenstrualSummary {
    // TODO: Ask Kim what the best way to do this is
    // Placebo week with birth control, what if you skip placebo week?
    let cycles = await fetchMenstrualFlowSamples(dateRange: .trailingMonthsFromNow(7))
    return MenstrualSummary(menstrualCycles: cycles)
  }

  /// Calculates an Exponential Weighted Moving Average (EWMA) for training load.
  /// EWMA gives more weight to recent days, making the metric more responsive to current behavior.
  /// Formula: EWMA_today = α × load_today + (1 - α) × EWMA_yesterday
  /// Uses standard EWMA decay: α = 2/(decayDays + 1)
  /// - Parameters:
  ///   - dailyLoads: Dictionary mapping dates to their training load values
  ///   - endDate: The end date for the EWMA calculation
  ///   - decayDays: The decay constant (7 for acute, 28 for chronic) - controls how fast old data fades
  ///   - allDates: All available dates sorted oldest to newest
  /// - Returns: The EWMA value ending on endDate
  private func calculateEWMA(
    dailyLoads: [Date: Double],
    endDate: Date,
    decayDays: Int,
    allDates: [Date]
  ) -> Double {
    // Standard EWMA decay constant
    let alpha = 2.0 / Double(decayDays + 1)
    var ewma: Double = 0
    var isFirst = true

    // Process ALL historical dates (sorted oldest to newest) up to endDate
    let calendar = Calendar.current
    let endDayStart = calendar.startOfDay(for: endDate)
    let relevantDates = allDates.filter { $0 <= endDayStart }

    for date in relevantDates {
      let load = dailyLoads[date] ?? 0
      if isFirst {
        ewma = load
        isFirst = false
      } else {
        ewma = alpha * load + (1 - alpha) * ewma
      }
    }
    return ewma
  }

  func fetchTrainingLoadSummary() async -> TrainingLoadSummary? {
    let dateRange = DateRange.trailingDaysFromNow(56)
    let workouts = await fetchWorkouts(dateRange: dateRange)
    
    // Fetch active energy burned for all 56 days
    let activeEnergyData = (try? await healthStore.fetchCollatedQuantity(
      quantityTypeID: .activeEnergyBurned,
      unit: .largeCalorie(),
      dateRange: dateRange
    )) ?? []
    
    // Need either workouts or active energy data
    guard workouts.isNotEmpty || activeEnergyData.isNotEmpty else { return nil }
    
    // Calculate daily training loads for all 56 days
    var dailyLoads: [Date: Double] = [:]
    
    // First, add workout-based loads
    for workout in workouts {
      let workoutDate = Calendar.current.startOfDay(for: workout.startDate)
      let duration = workout.duration / 60 // Convert to minutes
      
      // Fetch effort scores for this workout
      let userEffortSamples = try? await fetchSamples(
        for: HKQuantityType(.workoutEffortScore),
        dateRange: DateRange(workout.startDate, workout.endDate)
      ) as? [HKQuantitySample]
      let userEffortScore = userEffortSamples?.first?.quantity.doubleValue(for: .appleEffortScore())

      let estimatedEffortSamples = try? await fetchSamples(
        for: HKQuantityType(.estimatedWorkoutEffortScore),
        dateRange: DateRange(workout.startDate, workout.endDate)
      ) as? [HKQuantitySample]
      let estimatedEffortScore = estimatedEffortSamples?.first?.quantity.doubleValue(for: .appleEffortScore())

      // Use user score if available, otherwise estimated score
      if let effortScore = userEffortScore ?? estimatedEffortScore {
        let workoutLoad = effortScore * duration
        dailyLoads[workoutDate, default: 0] += workoutLoad
      }
    }
    
    // Add all-day load adjustments based on active calories deviation from baseline
    let caloriesByDate = Dictionary(uniqueKeysWithValues: activeEnergyData.map {
      (Calendar.current.startOfDay(for: $0.date), $0.quantity.doubleValue(for: .largeCalorie()))
    })

    // Calculate rolling 28-day baseline for each day
    for date in Calendar.current.dateCollection(for: dateRange) {
      let dayStart = Calendar.current.startOfDay(for: date)

      // Calculate 7-day baseline ending on the previous day
      let baselineEndDate = Calendar.current.date(byAdding: .day, value: -1, to: dayStart) ?? dayStart
      let baselineStartDate = Calendar.current.date(byAdding: .day, value: -7, to: baselineEndDate) ?? baselineEndDate

      var baselineCalories: [Double] = []
      for baselineDate in Calendar.current.dateCollection(for: DateRange(baselineStartDate, baselineEndDate)) {
        if let calories = caloriesByDate[Calendar.current.startOfDay(for: baselineDate)] {
          baselineCalories.append(calories)
        }
      }

      let baseline = baselineCalories.isEmpty ? 0 : baselineCalories.reduce(0, +) / Double(baselineCalories.count)

      // Get today's active calories
      let todayCalories = caloriesByDate[dayStart] ?? 0

      // Calculate all-day adjustment (both positive and negative deviations)
      // Scaling factor of 2.0 to balance with workout loads
      let allDayAdjustment = (todayCalories - baseline) / 2.0

      // Add all-day adjustment to existing workout load, clamped to zero minimum
      // This prevents rest days from going negative and creating extreme percentages
      dailyLoads[dayStart] = max(0, dailyLoads[dayStart, default: 0] + allDayAdjustment)
    }
    
    // Generate date samples for the last 28 days
    let startDate = Calendar.current.date(byAdding: .day, value: -27, to: Date()) ?? Date()
    let endDate = Date()
    let last28Days = Calendar.current.dateCollection(for: DateRange(startDate, endDate))

    // Collect all dates from dailyLoads sorted oldest to newest for EWMA calculation
    let allDates = Array(dailyLoads.keys).sorted()

    var sevenDayTrend: [DateValueSample] = []
    var twentyEightDayTrend: [DateValueSample] = []
    var dailyLoadSamples: [DateValueSample] = []

    for date in last28Days {
      let dayStart = Calendar.current.startOfDay(for: date)

      // Calculate 7-day EWMA (acute load) ending on this date
      // Uses all historical data with 7-day decay constant - responds quickly to recent changes
      let sevenDayAvg = calculateEWMA(dailyLoads: dailyLoads, endDate: dayStart, decayDays: 7, allDates: allDates)

      // Calculate 28-day EWMA (chronic load) ending on this date
      // Uses all historical data with 28-day decay constant - retains more baseline fitness data
      let twentyEightDayAvg = calculateEWMA(dailyLoads: dailyLoads, endDate: dayStart, decayDays: 28, allDates: allDates)

      sevenDayTrend.append(DateValueSample(date: date, value: sevenDayAvg))
      twentyEightDayTrend.append(DateValueSample(date: date, value: twentyEightDayAvg))
      dailyLoadSamples.append(DateValueSample(date: date, value: dailyLoads[dayStart] ?? 0))
    }
    
    // Current averages (most recent values)
    let currentSevenDayAverage = sevenDayTrend.last?.value ?? 0
    let currentTwentyEightDayAverage = twentyEightDayTrend.last?.value ?? 0
    
    // Calculate percentage difference
    let percentageDifference: Double
    if currentTwentyEightDayAverage > 0 {
      percentageDifference = ((currentSevenDayAverage - currentTwentyEightDayAverage) / currentTwentyEightDayAverage) * 100
    } else {
      percentageDifference = 0
    }
    
    let status = TrainingLoadStatus.from(percentageDifference: percentageDifference)
    
    return TrainingLoadSummary(
      dateRange: DateRange.trailingDaysFromNow(28),
      currentSevenDayAverage: currentSevenDayAverage,
      currentTwentyEightDayAverage: currentTwentyEightDayAverage,
      percentageDifference: percentageDifference,
      status: status,
      sevenDayTrend: sevenDayTrend,
      twentyEightDayTrend: twentyEightDayTrend,
      dailyLoads: dailyLoadSamples
    )
  }
}

// MARK: Recommended Ranges

public extension HealthStoreFetcher {

  /// - note: https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/exercise-intensity/art-20046887
  func heartRateZones() async -> HeartRateZones? {
    // Use age stored in HealthManager (defaults) over HealthKit.
    let age = await HealthManager.shared.age()
    let projectedMax = 208 - (Double(age) * 0.7)

    guard let restingHeartRate = try? await healthStore.fetchDailyAverageQuantity(
      for: .restingHeartRate,
      unit: .bpm(),
      dateRange: .trailingMonthsFromNow(6),
      option: .discreteAverage
    ).doubleValue(for: .bpm()).rounded() else {
      return nil
    }

    let heartRateReserve = projectedMax - restingHeartRate

    return HeartRateZones(
      heartRateReserve: heartRateReserve,
      restingHeartRate: restingHeartRate,
      maxHeartRate: projectedMax,
      zone1: (0.5 * heartRateReserve) + restingHeartRate,
      zone2: (0.6 * heartRateReserve) + restingHeartRate,
      zone3: (0.7 * heartRateReserve) + restingHeartRate,
      zone4: (0.8 * heartRateReserve) + restingHeartRate,
      zone5: (0.9 * heartRateReserve) + restingHeartRate
    )
  }
}

// MARK: - Alcohol

public extension HealthStoreFetcher {

  func fetchAlcoholSummary(
    dateRange: DateRange = .trailingDaysFromNow(7),
    interval: DateComponents = DateComponents(day: 1),
    sex: HKBiologicalSex = .notSet
  ) async -> AlcoholSummary {
    // Fetch data with requested interval for chart display
    let samples = await fetchCollatedQuantity(
      for: .numberOfAlcoholicBeverages,
      unit: .count(),
      interval: interval,
      dateRange: dateRange
    )

    guard samples.isNotEmpty else {
      return .empty
    }

    // Convert to chart data (may be daily or weekly depending on interval)
    let chartData = samples.map { sample in
      AlcoholSummary.DailyAlcoholData(
        date: sample.date,
        drinks: Int(sample.quantity.doubleValue(for: .count()))
      )
    }

    let total = chartData.reduce(0) { $0 + $1.drinks }

    // For binge/heavy day calculations, always use daily data
    let dailySamples: [DateQuantitySample]
    if interval == DateComponents(day: 1) {
      dailySamples = samples
    } else {
      dailySamples = await fetchCollatedQuantity(
        for: .numberOfAlcoholicBeverages,
        unit: .count(),
        interval: DateComponents(day: 1),
        dateRange: dateRange
      )
    }

    // Calculate binge days (sex-specific thresholds) using daily data
    let bingeThreshold = (sex == .male) ? 5 : 4
    let heavyThreshold = (sex == .male) ? 10 : 8

    let bingeDays = dailySamples.filter {
      Int($0.quantity.doubleValue(for: .count())) >= bingeThreshold
    }.count
    let heavyDays = dailySamples.filter {
      Int($0.quantity.doubleValue(for: .count())) >= heavyThreshold
    }.count

    return AlcoholSummary(
      weeklyTotal: total,
      dailyData: chartData,
      bingeDays: bingeDays,
      heavyDays: heavyDays
    )
  }
}
