//
//  HealthStoreFetcher.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation
import HealthKit
import BloomFoundation

final class HealthStoreFetcher: Sendable {
    static let shared = HealthStoreFetcher()

    private let healthStore = HKHealthStore()

    private init() { }
}

// MARK: Fetching Data

extension HealthStoreFetcher {

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

    func fetchSamples(for sampleType: HKSampleType, dateRange: DateRange) async -> [HKSample] {
        (try? await healthStore.fetchSamples(for: sampleType, dateRange: dateRange)) ?? []
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
                let dietaryEnergy = dietary?.first(where: { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) })?.quantity
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

    func fetchWorkouts(activityType: HKWorkoutActivityType? = nil, dateRange: DateRange) async -> [HKWorkout] {
        (try? await healthStore.fetchWorkouts(activityType: activityType, dateRange: dateRange)) ?? []
    }

    func fetchWorkouts(activityTypes: [HKWorkoutActivityType], dateRange: DateRange) async -> [HKWorkout] {
        (try? await healthStore.fetchWorkouts(activityTypes: activityTypes, dateRange: dateRange)) ?? []
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

        Calendar.current.iterate(dateRange: dateRange, by: .init(day: 1)) { date in
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

    func fetchWorkoutHeartRateReports(dateRange: DateRange) async -> [WorkoutHeartRateReport] {
        guard let targetHeartRateZones = await heartRateZones() else { return [] }

        let workouts = (try? await healthStore.fetchWorkouts(dateRange: dateRange)) ?? []
        var reports = [WorkoutHeartRateReport]()

        for workout in workouts {
            guard let heartRateSamples = try? await healthStore.fetchSamples(
                for: HKQuantityType(.heartRate),
                dateRange: workout.dateRange
            ) as? [HKQuantitySample] else {
                continue
            }

            guard heartRateSamples.isNotEmpty else { continue }

            reports.append(
                WorkoutHeartRateReport(
                    workout: workout,
                    heartRateSamples: heartRateSamples,
                    heartRateZones: targetHeartRateZones
                )
            )
        }

        return reports
    }

    func fetchCollatedWorkoutHeartRateReports(
        dateRange: DateRange
    ) async -> [DateCollatedWorkoutHeartRateReport] {
        guard let targetHeartRateZones = await heartRateZones() else { return [] }

        let collatedWorkouts = await fetchCollatedWorkouts(dateRange: dateRange)

        var collatedReports = [DateCollatedWorkoutHeartRateReport]()

        for collatedWorkout in collatedWorkouts {
            var reports = [WorkoutHeartRateReport]()

            for workout in collatedWorkout.workouts {
                guard let heartRateSamples = try? await healthStore.fetchSamples(
                    for: HKQuantityType(.heartRate),
                    dateRange: workout.dateRange
                ) as? [HKQuantitySample] else {
                    continue
                }

                reports.append(
                    WorkoutHeartRateReport(
                        workout: workout,
                        heartRateSamples: heartRateSamples,
                        heartRateZones: targetHeartRateZones
                    )
                )
            }

            let collatedReport = DateCollatedWorkoutHeartRateReport(date: collatedWorkout.date, reports: reports)
            collatedReports.append(collatedReport)
        }

        return collatedReports
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

// MARK: Writing Data

extension HealthStoreFetcher {

    func write(sample: HKObject) async throws {
        try await healthStore.save(sample)
    }

    func write(samples: [HKObject]) async throws {
        try await healthStore.save(samples)
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

            let timePeriod: Int = 10 // minutes
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
                    interval: .init(minute: timePeriod),
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

                    let dateRange = DateRange(shiftedStart, shiftedEnd)
                    let samples = try await healthStore.fetchSamples(
                        for: HKQuantityType(.appleSleepingWristTemperature),
                        dateRange: dateRange
                    ) as? [HKQuantitySample] ?? []

                    for sample in samples {
                        let dataPoint = SleepAnalysis.WristTemperatureDataPoint(
                            averageWristTemperature: sample.quantity.doubleValue(for: .degreeFahrenheit()),
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

extension HealthStoreFetcher {

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
                samples.append(.init(date: basalSample.date, value: 1))
                continue
            }

            let sum = activeSample.quantity.doubleValue(for: unit) + basalSample.quantity.doubleValue(for: unit)
            let ratio = sum / basalSample.quantity.doubleValue(for: unit)

            samples.append(.init(date: basalSample.date, value: ratio))
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
        let fiber = await fetchNutritionalDailyAverage(for: .dietaryFiber, unit: .gram(), dateRange: dateRange)
        let sugar = await fetchNutritionalDailyAverage(for: .dietarySugar, unit: .gram(), dateRange: dateRange)
        let water = await fetchNutritionalDailyAverage(for: .dietaryWater, unit: .literUnit(with: .milli), dateRange: dateRange)

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

        return .init(
            numberOfNutritionLogDays: dietaryEnergyCountAboveZero,
            numberOfProteinLogDays: proteinCountAboveZero,
            basalEnergyBurned: basalEnergyBurned,
            activeEnergyBurned: activeEnergyBurned,
            dietaryEnergy: dietaryEnergy,
            averageProtein: protein,
            averageCarbohydrates: carbohydrates,
            averageFat: fat,
            averageFiber: fiber,
            averageSugar: sugar,
            averageWater: water
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
        let bodyMass = try? await healthStore.fetchQuantity(for: .bodyMass, dateRange: dateRange)

        return BodyCompositionMonthlySummary.Details(
            bodyFatPercentage: bodyFatPercentage,
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
}

// MARK: Recommended Ranges

extension HealthStoreFetcher {

    /// - note: https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/exercise-intensity/art-20046887
    func heartRateZones() async -> HeartRateZones? {
        guard let age = healthStore.age() else { return nil }

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
