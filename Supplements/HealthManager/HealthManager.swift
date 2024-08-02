//
//  HealthManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation
import HealthKit
import AppFoundations

extension TimeInterval {
    static let maxSleepGroupTimeDistance: TimeInterval = 7200 // 2 hours
}

final class HealthManager: ObservableObject {
    static let shared = HealthManager()

    @Published var authStatus: HKAuthorizationRequestStatus = .unknown

    @Published var sleepAnalysis7Days: [SleepAnalysis]?
    @Published var sleepAnalysis30Days: [SleepAnalysis]?
    @Published var sleepAnalysisPrevious30Days: [SleepAnalysis]?

    let healthStore = HKHealthStore()
    private let throttler = Throttler(timeInterval: 600)

    private var sleepDataListenerTask: Task<Void, Error>? = nil

    private init() {
        Task {
            try? await checkAccess()
        }
    }

    let types: Set = [
        HKQuantityType(.bodyMass),
        HKCharacteristicType(.dateOfBirth),
        HKCharacteristicType(.biologicalSex),
        HKObjectType.activitySummaryType(),
        HKQuantityType(.appleExerciseTime),
        HKQuantityType(.stepCount),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.vo2Max),
        HKQuantityType(.timeInDaylight),
        HKCategoryType(.sleepAnalysis),
        HKQuantityType(.basalEnergyBurned),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.bodyFatPercentage),
        HKObjectType.workoutType(),
        HKCategoryType(.mindfulSession),
        HKQuantityType(.heartRate),
        HKQuantityType(.environmentalAudioExposure),
        HKQuantityType(.respiratoryRate),
        HKQuantityType(.appleSleepingWristTemperature),
        HKCategoryType(.appleWalkingSteadinessEvent),
        HKQuantityType(.sixMinuteWalkTestDistance),
        HKQuantityType(.walkingDoubleSupportPercentage),
        HKQuantityType(.bloodPressureSystolic),
        HKQuantityType(.bloodPressureDiastolic),
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.heartRateRecoveryOneMinute)
//        HKQuantityType(.dietaryEnergyConsumed),
//        HKQuantityType(.dietaryBiotin),
//        HKQuantityType(.dietaryCaffeine),
//        HKQuantityType(.dietaryCalcium),
//        HKQuantityType(.dietaryCarbohydrates),
//        HKQuantityType(.dietaryChloride),
//        HKQuantityType(.dietaryCholesterol),
//        HKQuantityType(.dietaryChromium),
//        HKQuantityType(.dietaryCopper),
//        HKQuantityType(.dietaryEnergyConsumed),
//        HKQuantityType(.dietaryFatMonounsaturated),
//        HKQuantityType(.dietaryFatPolyunsaturated),
//        HKQuantityType(.dietaryFatSaturated),
//        HKQuantityType(.dietaryFatTotal),
//        HKQuantityType(.dietaryFiber),
//        HKQuantityType(.dietaryFolate),
//        HKQuantityType(.dietaryIodine),
//        HKQuantityType(.dietaryIron),
//        HKQuantityType(.dietaryMagnesium),
//        HKQuantityType(.dietaryManganese),
//        HKQuantityType(.dietaryMolybdenum),
//        HKQuantityType(.dietaryNiacin),
//        HKQuantityType(.dietaryPantothenicAcid),
//        HKQuantityType(.dietaryPhosphorus),
//        HKQuantityType(.dietaryPotassium),
//        HKQuantityType(.dietaryProtein),
//        HKQuantityType(.dietaryRiboflavin),
//        HKQuantityType(.dietarySelenium),
//        HKQuantityType(.dietarySodium),
//        HKQuantityType(.dietarySugar),
//        HKQuantityType(.dietaryThiamin),
//        HKQuantityType(.dietaryVitaminA),
//        HKQuantityType(.dietaryVitaminB12),
//        HKQuantityType(.dietaryVitaminB6),
//        HKQuantityType(.dietaryVitaminC),
//        HKQuantityType(.dietaryVitaminD),
//        HKQuantityType(.dietaryVitaminE),
//        HKQuantityType(.dietaryVitaminK),
//        HKQuantityType(.dietaryWater),
//        HKQuantityType(.dietaryZinc)
    ]
}

extension HealthManager {

    var isAuthorized: Bool {
        authStatus == .unnecessary
    }

    func checkAccess() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.getRequestStatusForAuthorization(toShare: [], read: types) { authStatus, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                DispatchQueue.main.async {
                    self.authStatus = authStatus
                }
                continuation.resume()
            }
        }
    }

    func requestAccessIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        try? await checkAccess()
        if authStatus == .shouldRequest {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: types)
            } catch {
                print(error)
            }
        }
        try? await checkAccess()
    }
}

extension HealthManager {

    func age() -> Int? {
        healthStore.age()
    }

    func sex() -> String? {
        healthStore.sex()
    }

    func fetchBodyWeight() async -> HKQuantitySample? {
        let bodyMassType = HKQuantityType(.bodyMass)
        let descriptor = HKSampleQueryDescriptor(
            predicates:[.quantitySample(type: bodyMassType)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )

        do {
            let results = try await descriptor.result(for: healthStore)
            return results.first
        } catch {
            print(error)
        }
        return nil
    }

    func fetchThisWeekSumQuantity(for quantityType: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        let endDate = Date.now
        guard let startDate = Calendar.current.startOfWeek(for: endDate) else { return 0 }

        do {
            return try await healthStore.fetchQuantity(
                for: quantityType,
                start: startDate,
                end: endDate,
                option: .cumulativeSum,
                unit: unit
            ).0
        } catch {
            print(error)
        }
        return 0
    }

    func fetchWeeklyAverage(for quantityType: HKQuantityTypeIdentifier, unit: HKUnit, numWeeks: Int) async -> Double {
        guard
            let endDate = Calendar.current.startOfWeek(for: .now),
            let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -numWeeks, to: endDate)
        else {
            return 0
        }

        do {
            let result = try await healthStore.fetchQuantity(
                for: quantityType,
                start: startDate,
                end: endDate,
                option: .cumulativeSum,
                unit: unit
            ).0

            return result / Double(numWeeks)
        } catch {
            print(error)
        }
        return 0
    }

    func fetchExerciseMinutes() async -> (Double, Int)? {
        do {
            return try await healthStore.fetchQuantity(
                for: .appleExerciseTime,
                pastMonths: 1,
                option: .cumulativeSum,
                unit: .minute()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchExerciseMinutes(startDate: Date, endDate: Date) async -> [DateQuantitySample] {
        do {
            return try await healthStore.fetchCollectionQuantity(
                quantityTypeID: .appleExerciseTime,
                unit: .minute(),
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchAverageSteps() async -> (Double, Int)? {
        do {
            return try await healthStore.fetchQuantity(
                for: .stepCount,
                pastMonths: 1,
                option: .cumulativeSum,
                unit: .count()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchHRV() async -> (Double, Int)? {
        do {
            return try await healthStore.fetchQuantity(
                for: .heartRateVariabilitySDNN,
                pastMonths: 1,
                unit: .secondUnit(with: .milli)
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchRestingHeartRate(period: Int = 7) async -> [DateQuantitySample] {
        do {
            let samples = try await healthStore.fetchSamples(for: .restingHeartRate, previousDays: period)

            return samples.compactMap { sample in
                sample as? HKQuantitySample
            }.map { sample in
                let value = sample.quantity.doubleValue(for: .bpm())
                return DateQuantitySample(
                    date: sample.startDate,
                    quantity: value,
                    unit: "bpm"
                )
            }
        } catch {
            print(error)
        }
        return []
    }

    func fetchAverageRestingHeartRate(endDate: Date, period: Int = 7) async -> Double? {
        do {
            guard let startDate = Calendar.current.date(byAdding: .day, value: -period, to: endDate) else {
                return 0
            }

            return try await healthStore.fetchQuantity(
                for: .restingHeartRate,
                start: startDate,
                end: endDate,
                unit: .bpm()
            ).0
        } catch {
            print(error)
        }
        return nil
    }

    func fetchVO2Max(numPastMonths: Int = 0) async -> (Double, Int)? {
        do {
            guard let endDate = Calendar.current.date(byAdding: .month, value: -numPastMonths, to: .now),
                  let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)
            else {
                return nil
            }

            return try await healthStore.fetchQuantity(
                for: .vo2Max,
                start: startDate,
                end: endDate,
                option: .discreteAverage,
                unit: .vo2Max()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchHeartRateRecovery(numPastMonths: Int = 0) async -> (Double, Int)? {
        do {
            guard let endDate = Calendar.current.date(byAdding: .month, value: -numPastMonths, to: .now),
                  let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)
            else {
                return nil
            }

            return try await healthStore.fetchQuantity(
                for: .heartRateRecoveryOneMinute,
                start: startDate,
                end: endDate,
                option: .discreteAverage,
                unit: .bpm()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchVO2Max(startDate: Date, endDate: Date) async -> [DateAverageQuantitySample] {
        do {
            return try await healthStore.fetchAverageStatistics(
                quantityTypeID: .vo2Max,
                unit: .vo2Max(),
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchAverageTimeInDaylight() async -> (Double, Int)? {
        do {
            return try await healthStore.fetchQuantity(
                for: .timeInDaylight,
                pastMonths: 1,
                option: .cumulativeSum,
                unit: .minute()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchTimeInDaylight(periodDays: Int = 14) async -> [DateQuantitySample] {
        let endDate = Date.now
        guard let startDate = Calendar.current.date(byAdding: .day, value: -periodDays, to: endDate) else {
            return []
        }

        return await fetchTimeInDaylight(startDate: startDate, endDate: endDate)
    }

    func fetchTimeInDaylight(startDate: Date, endDate: Date) async -> [DateQuantitySample] {
        do {
            return try await healthStore.fetchCollectionQuantity(
                quantityTypeID: .timeInDaylight,
                unit: .minute(),
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchBasalEnergy(numPastMonths: Int = 0) async -> (Double, Int)? {
        do {
            guard let endDate = Calendar.current.date(byAdding: .month, value: -numPastMonths, to: .now),
                  let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)
            else {
                return nil
            }

            return try await healthStore.fetchQuantity(
                for: .basalEnergyBurned,
                start: startDate,
                end: endDate,
                option: .cumulativeSum,
                unit: .largeCalorie()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchActiveEnergy(numPastMonths: Int = 0) async -> (Double, Int)? {
        do {
            guard let endDate = Calendar.current.date(byAdding: .month, value: -numPastMonths, to: .now),
                  let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)
            else {
                return nil
            }

            return try await healthStore.fetchQuantity(
                for: .activeEnergyBurned,
                start: startDate,
                end: endDate,
                option: .cumulativeSum,
                unit: .largeCalorie()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchActiveEnergy(startDate: Date, endDate: Date) async -> [DateQuantitySample] {
        do {
            return try await healthStore.fetchCollectionQuantity(
                quantityTypeID: .activeEnergyBurned,
                unit: .largeCalorie(),
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchWorkoutSummaryLastTwoWeeks() async -> [WorkoutSummary] {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) else {
                return []
            }

            return try await healthStore.fetchWorkoutSummaries(startDate: startDate, endDate: endDate)
        } catch {
            print(error)
        }
        return []
    }

    func fetchWorkoutSummaries(activityType: HKWorkoutActivityType? = nil, numWeeks: Int) async -> [WorkoutSummary] {
        guard
            let endDate = Calendar.current.startOfWeek(for: .now),
            let startDate = Calendar.current.date(byAdding: .day, value: -numWeeks, to: endDate)
        else { return [] }

        return await fetchWorkoutSummaries(startDate: startDate, endDate: endDate, activityType: activityType)
    }

    func fetchWorkoutSummaries(
        startDate: Date,
        endDate: Date,
        activityType: HKWorkoutActivityType? = nil
    ) async -> [WorkoutSummary] {
        do {
            return try await healthStore.fetchWorkoutSummaries(
                startDate: startDate,
                endDate: endDate,
                activityType: activityType
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchWorkoutSummariesThisWeek(activityType: HKWorkoutActivityType? = nil) async -> [WorkoutSummary] {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.startOfWeek(for: endDate) else { return [] }

            return try await healthStore.fetchWorkoutSummaries(
                startDate: startDate,
                endDate: endDate,
                activityType: activityType
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchBodyFatPercentage(numPastMonths: Int = 0) async -> (Double, Int)? {
        do {
            guard let endDate = Calendar.current.date(byAdding: .month, value: -numPastMonths, to: .now),
                  let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)
            else {
                return nil
            }

            return try await healthStore.fetchQuantity(
                for: .bodyFatPercentage,
                start: startDate,
                end: endDate,
                option: .discreteAverage,
                unit: .percent()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchMonthlyMobilitySummary() async -> MobilityMonthlySummary? {
        do {
            let endDate = Date.now

            guard let midDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate),
                  let startDate = Calendar.current.date(byAdding: .month, value: -1, to: midDate)
            else {
                return nil
            }

            let doubleSupportTime = try await healthStore.fetchQuantity(
                for: .walkingDoubleSupportPercentage,
                start: midDate,
                end: endDate,
                option: .discreteAverage,
                unit: .percent()
            )

            let sixMinuteWalkDistance = try await healthStore.fetchQuantity(
                for: .sixMinuteWalkTestDistance,
                start: midDate,
                end: endDate,
                option: .discreteAverage,
                unit: .meter()
            )

            let walkingSteadiness = try await healthStore.fetchSamples(
                for: HKCategoryType(.appleWalkingSteadinessEvent),
                start: midDate,
                end: endDate
            ).compactMap { sample in
                (sample as? HKCategorySample)?.walkingSteadinessCategory
            }

            let lastMonthDoubleSupportTime = try await healthStore.fetchQuantity(
                for: .walkingDoubleSupportPercentage,
                start: startDate,
                end: midDate,
                option: .discreteAverage,
                unit: .percent()
            )

            let lastMonthSixMinuteWalkDistance = try await healthStore.fetchQuantity(
                for: .sixMinuteWalkTestDistance,
                start: startDate,
                end: midDate,
                option: .discreteAverage,
                unit: .meter()
            )

            let lastMonthWalkingSteadiness = try await healthStore.fetchSamples(
                for: HKCategoryType(.appleWalkingSteadinessEvent),
                start: startDate,
                end: midDate
            ).compactMap { sample in
                (sample as? HKCategorySample)?.walkingSteadinessCategory
            }

            return MobilityMonthlySummary(
                doubleSupportTimePercent: doubleSupportTime.0,
                sixMinuteWalkDistance: sixMinuteWalkDistance.0,
                walkingSteadiness: walkingSteadiness,
                lastMonthDoubleSupportTimePercent: lastMonthDoubleSupportTime.0,
                lastMonthSixMinuteWalkDistance: lastMonthSixMinuteWalkDistance.0,
                lastMonthWalkingSteadiness: lastMonthWalkingSteadiness
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchStressMonthlySummary() async -> StressMonthlySummary? {
        let endDate = Date.now

        guard let midDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate),
              let startDate = Calendar.current.date(byAdding: .month, value: -1, to: midDate)
        else {
            return nil
        }

        let hrvAverage = try? await healthStore.fetchQuantity(
            for: .heartRateVariabilitySDNN,
            start: midDate,
            end: endDate,
            unit: .secondUnit(with: .milli)
        )
        let hrvSamples = try? await healthStore.fetchSamples(
            for: .heartRateVariabilitySDNN,
            start: midDate,
            end: endDate
        ).compactMap({ $0 as? HKQuantitySample }).map({ $0.quantity.doubleValue(for: .secondUnit(with: .milli)) })
        let rhrAverage = try? await healthStore.fetchQuantity(
            for: .restingHeartRate,
            start: midDate,
            end: endDate,
            unit: .bpm()
        )
        let systolicAverage = try? await healthStore.fetchQuantity(
            for: .bloodPressureSystolic,
            start: midDate,
            end: endDate,
            unit: .millimeterOfMercury()
        )
        let diastolicAverage = try? await healthStore.fetchQuantity(
            for: .bloodPressureDiastolic,
            start: midDate,
            end: endDate,
            unit: .millimeterOfMercury()
        )

        let lastMonthHRVAverage = try? await healthStore.fetchQuantity(
            for: .heartRateVariabilitySDNN,
            start: startDate,
            end: midDate,
            unit: .secondUnit(with: .milli)
        )
        let lastMonthHRVSamples = try? await healthStore.fetchSamples(
            for: .heartRateVariabilitySDNN,
            start: startDate,
            end: midDate
        ).compactMap({ $0 as? HKQuantitySample }).map({ $0.quantity.doubleValue(for: .secondUnit(with: .milli)) })
        let lastMonthRHRAverage = try? await healthStore.fetchQuantity(
            for: .restingHeartRate,
            start: startDate,
            end: midDate,
            unit: .bpm()
        )
        let lastMonthSystolicAverage = try? await healthStore.fetchQuantity(
            for: .bloodPressureSystolic,
            start: startDate,
            end: midDate,
            unit: .millimeterOfMercury()
        )
        let lastMonthDiastolicAverage = try? await healthStore.fetchQuantity(
            for: .bloodPressureDiastolic,
            start: startDate,
            end: midDate,
            unit: .millimeterOfMercury()
        )

        return StressMonthlySummary(
            avgHeartRateVariability: hrvAverage?.0,
            varHeartRateVariability: hrvSamples?.variance(keyPath: \.self),
            restingHeartRate: rhrAverage?.0,
            sleepScore: sleepAnalysis30Days?.average(keyPath: \.overallScoreDouble),
            bloodPressureSystolic: systolicAverage?.0,
            bloodPressureDiastolic: diastolicAverage?.0,
            lastMonthAvgHeartRateVariability: lastMonthHRVAverage?.0,
            lastMonthVarHeartRateVariability: lastMonthHRVSamples?.variance(keyPath: \.self),
            lastMonthRestingHeartRate: lastMonthRHRAverage?.0,
            lastMonthSleepScore: sleepAnalysisPrevious30Days?.average(keyPath: \.overallScoreDouble),
            lastMonthBloodPressureSystolic: lastMonthSystolicAverage?.0,
            lastMonthBloodPressureDiastolic: lastMonthDiastolicAverage?.0
        )
    }

    func fetchAverageMeditationMinutes(previousDays: Int = 7) async -> (Double, Int)? {
        do {
            let meditationType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
            let samples = try await healthStore.fetchSamples(for: meditationType, previousDays: previousDays)

            let meditationMinutes = samples.reduce(0) { (total, sample) -> Double in
                total + sample.endDate.timeIntervalSince(sample.startDate) / 60
            }

            return (meditationMinutes / Double(previousDays), previousDays)
        } catch {
            print(error)
        }
        return nil
    }

    func fetchWeeklyAverageMeditationMinutes(numWeeks: Int) async -> Double {
        do {
            guard
                let endDate = Calendar.current.startOfWeek(for: .now),
                let startDate = Calendar.current.date(byAdding: .day, value: -numWeeks, to: endDate)
            else { return 0 }

            let meditationType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
            let samples = try await healthStore.fetchSamples(
                for: meditationType,
                start: startDate,
                end: endDate
            )

            let meditationMinutes = samples.reduce(0) { (total, sample) -> Double in
                total + sample.timeInterval / 60
            }

            return meditationMinutes / Double(numWeeks)
        } catch {
            print(error)
        }
        return 0
    }

    func fetchAverageMeditationMinutesThisWeek() async -> Double {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.startOfWeek(for: endDate) else { return 0 }

            let meditationType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
            let samples = try await healthStore.fetchSamples(
                for: meditationType,
                start: startDate,
                end: endDate
            )

            let meditationMinutes = samples.reduce(0) { (total, sample) -> Double in
                total + sample.timeInterval / 60
            }

            return meditationMinutes
        } catch {
            print(error)
        }
        return 0
    }

    func fetchMeditationMinutes(periodDays: Int = 14) async -> [DateQuantitySample] {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.date(byAdding: .day, value: -periodDays, to: endDate) else {
                return []
            }

            let meditationType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!

            let samples = try await healthStore.fetchSamples(for: meditationType, start: startDate, end: endDate)

            var quantitySamples = [DateQuantitySample]()

            for sample in samples {
                if
                    let lastSample = quantitySamples.last, 
                    Calendar.current.isDate(lastSample.date, equalTo: sample.endDate, toGranularity: .day) 
                {
                    quantitySamples[quantitySamples.count - 1].quantity += sample.timeInterval / 60
                    continue
                }

                let startOfDay = Calendar.current.startOfDay(for: sample.endDate)
                let newSample = DateQuantitySample(
                    date: startOfDay,
                    quantity: sample.timeInterval / 60,
                    unit: "minute"
                )
                quantitySamples.append(newSample)
            }

            return quantitySamples
        } catch {
            print(error)
        }
        return []
    }

    func fetchHeartRateVariability(periodDays: Int = 14) async -> [DateQuantitySample] {
        do {
            let samples = try await healthStore.fetchSamples(for: .heartRateVariabilitySDNN, previousDays: periodDays)

            return samples.compactMap { sample in
                sample as? HKQuantitySample
            }.map { sample in
                let value = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                return DateQuantitySample(
                    date: sample.startDate,
                    quantity: value,
                    unit: "milliseconds"
                )
            }
        } catch {
            print(error)
        }
        return []
    }
}

// MARK: - Sleep

extension HealthManager {

    func observeSleepData() {
        do {
            try healthStore.observeChanges(sampleType: HKCategoryType(.sleepAnalysis)) { [weak self, healthStore] in
                let endDate = Date.now
                let startDate = Calendar.current.sleepStartDate(previousDays: 30, endDate: endDate)
                let lastMonthEndDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) ?? endDate
                let lastMonthStartDate = Calendar.current.sleepStartDate(previousDays: 30, endDate: lastMonthEndDate)

                let thisMonthSamples = try await healthStore.fetchSamples(
                    for: HKCategoryType(.sleepAnalysis),
                    start: startDate,
                    end: endDate
                )
                let lastMonthSamples = try await healthStore.fetchSamples(
                    for: HKCategoryType(.sleepAnalysis),
                    start: lastMonthStartDate,
                    end: lastMonthEndDate
                )

                let lastPreviousSleepAnalysis = self?.sleepAnalysis30Days?.last

                let thisMonthSleepAnalysis = await self?.processSleepAnalysis(samples: thisMonthSamples) ?? []
                let lastMonthSleepAnalysis = await self?.processSleepAnalysis(samples: lastMonthSamples) ?? []

                let newPreviousSleepAnalysis = thisMonthSleepAnalysis.last

                if (newPreviousSleepAnalysis?.endDate ?? .distantPast) > (lastPreviousSleepAnalysis?.endDate ?? .distantPast) && lastPreviousSleepAnalysis != nil {
                    // We've triggered from new data, not from app launch
                    await NotificationManager.shared.sendGoodMorningNotification(delay: 60 * 5)
                }

                await MainActor.run { [weak self] in
                    self?.sleepAnalysis7Days = thisMonthSleepAnalysis.suffix(7)
                    self?.sleepAnalysis30Days = thisMonthSleepAnalysis
                    self?.sleepAnalysisPrevious30Days = lastMonthSleepAnalysis
                }
            }
        } catch {
            print(error)
        }
    }

    func fetchSleepAnalysis(startDate: Date, endDate: Date) async -> [SleepAnalysis] {
        do {
            let samples = try await fetchSleepSamples(startDate: startDate, endDate: endDate)
            return await processSleepAnalysis(samples: samples)
        } catch {
            print(error)
        }
        return []
    }

    func fetchSleepSamples(startDate: Date, endDate: Date) async throws -> [HKSample] {
        try await healthStore.fetchSamples(
            for: HKCategoryType(.sleepAnalysis),
            start: startDate,
            end: endDate
        )
    }

    func processSleepAnalysis(samples: [HKSample]) async -> [SleepAnalysis] {
        let samples = samples as? [HKCategorySample] ?? []

        var groupedSamples = [[HKCategorySample]]()
        var currentGroup: [HKCategorySample] = []

        for sample in samples.reversed() {
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
                case .asleepCore:
                    coreSleepTime += sample.timeInterval
                case .asleepDeep:
                    deepSleepTime += sample.timeInterval
                case .asleepREM:
                    remSleepTime += sample.timeInterval
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

            guard startDate < endDate else {
                print("We somehow have a start date after the end date...")
                print("Start: \(startDate)")
                print("End: \(endDate)")
                continue
            }

            let timePeriod: Int = 10 // minutes

            // Sound levels
            var soundLevelDataPoints = [SleepAnalysis.SoundLevelDataPoint]()
            do {
                let samples = try await healthStore.fetchAverageStatistics(
                    quantityTypeID: .environmentalAudioExposure,
                    unit: .decibelAWeightedSoundPressureLevel(),
                    interval: DateComponents(minute: timePeriod),
                    startDate: startDate,
                    endDate: endDate
                )

                for sample in samples {
                    let dataPoint = SleepAnalysis.SoundLevelDataPoint(
                        decibelAWeightedSoundPressureLevelAverage: sample.averageQuantity,
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
                    startDate: startDate,
                    endDate: endDate
                )

                for sample in samples {
                    let dataPoint = SleepAnalysis.HeartRateDataPoint(
                        averageHeartRate: sample.averageQuantity,
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
                    startDate: startDate,
                    endDate: endDate
                )

                for sample in samples {
                    let dataPoint = SleepAnalysis.RespiratoryRateDataPoint(
                        averageRespiratoryRate: sample.averageQuantity,
                        startDate: sample.date,
                        timeRangeSeconds: TimeInterval(timePeriod * 60)
                    )
                    respiratoryRateDataPoints.append(dataPoint)
                }
            } catch {
                print(error)
            }

            // Wrist Temperature
            var wristTemperatureDataPoints = [SleepAnalysis.WristTemperatureDataPoint]()
            do {
                let samples = try await healthStore.fetchAverageStatistics(
                    quantityTypeID: .appleSleepingWristTemperature,
                    unit: .degreeFahrenheit(),
                    interval: .init(minute: timePeriod),
                    startDate: startDate,
                    endDate: endDate
                )

                for sample in samples {
                    let dataPoint = SleepAnalysis.WristTemperatureDataPoint(
                        averageWristTemperature: sample.averageQuantity,
                        startDate: sample.date,
                        timeRangeSeconds: TimeInterval(timePeriod * 60)
                    )
                    wristTemperatureDataPoints.append(dataPoint)
                }
            } catch {
                print(error)
            }

            let averageRestingHeartRate = await fetchAverageRestingHeartRate(endDate: startDate)

            let analysis = SleepAnalysis(
                startDate: startDate,
                endDate: endDate,
                deepSleepMinutes: deepSleepTime / 60,
                coreSleepMinutes: coreSleepTime / 60,
                remSleepMinutes: remSleepTime / 60,
                awakeSleepMinutes: awakeSleepTime / 60,
                averageRestingHeartRate: averageRestingHeartRate,
                environmentalSoundLevels: soundLevelDataPoints,
                heartRate: heartRateDataPoints,
                respiratoryRate: respiratoryRateDataPoints,
                wristTemperature: wristTemperatureDataPoints
            )
            sleepAnalysis.append(analysis)
        }

        return sleepAnalysis
    }
}

// MARK: - Heart Rate

extension HealthManager {

    func goalRestingHeartRateForUser() -> (Double, Double) {
        let age = healthStore.age()
        let sexObject = try? healthStore.biologicalSex()

        if let age {
            switch (age, sexObject?.biologicalSex) {

            case (18...25, .male):
                return (60, 70)
            case (26...35, .male), (18...25, .female):
                return (70, 75)
            case (36...45, .male), (26...35, .female):
                return (75, 80)
            case (46...55, .male), (36...45, .female):
                return (80, 85)
            case (56...65, .male), (46...55, .female):
                return (85, 90)
            case (66..., .male), (56...65, .female):
                return (90, 95)
            case (66..., .female):
                return (95, 100)
            default:
                break
            }
        }

        switch sexObject?.biologicalSex {
        case .female:
            return (65, 105)
        default:
            return (60, 100)
        }
    }

    func goalVO2MaxForUser() -> (Double, Double, Double)? {
        let age = healthStore.age() ?? 0
        let sexObject = try? healthStore.biologicalSex()

        switch sexObject?.biologicalSex {
        case .male:
            switch age {
            case 20...29: return (57.0, 48.0, 38.0)
            case 30...39: return (52.0, 43.0, 34.0)
            case 40...49: return (47.0, 38.0, 31.0)
            case 50...59: return (41.0, 33.0, 26.0)
            case 60...: return (36.0, 28.0, 18.0)
            default: return nil
            }
        case .female:
            switch age {
            case 20...29: return (47.0, 38.0, 29.0)
            case 30...39: return (38.0, 30.0, 24.0)
            case 40...49: return (34.0, 27.0, 21.0)
            case 50...59: return (29.0, 23.0, 19.0)
            case 60...: return (25.0, 20.0, 15.0)
            default: return nil
            }
        default:
            return nil
        }
    }

    func goalBodyFatPercentage() -> (Double, Double, Double, Double, Double)? {
        guard let sexObject = try? healthStore.biologicalSex() else { return nil }

        switch sexObject.biologicalSex {
        case .female:
            return (14, 21, 25, 32, 50)
        case .male:
            return (6, 14, 18, 25, 43)
        default:
            return nil
        }
    }

    func bloodPressureCategory(systolic: Double , diastolic: Double) -> BloodPressureCategory {
        if systolic > 180 || diastolic > 120 {
            return .hypertensiveCrisis
        } else if systolic > 140 || diastolic > 90 {
            return .hypertensionStage2
        } else if systolic > 130 || diastolic > 80 {
            return .hypertensionStage1
        } else if systolic > 120 {
            return .elevated
        } else {
            return .normal
        }
    }
}

extension HealthManager {

    // micrograms (mcg)
    func recommendedDailyBiotin() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if age < 4 {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 8)
        } else if age < 9 {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 12)
        } else if age < 14 {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 20)
        } else if age < 19 {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 25)
        } else {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 30)
        }
    }

    // milligrams (mg)
    func recommendedMaxDailyCaffeine() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if age < 12 {
            return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 0)
        } else if age < 19 {
            return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 100)
        } else {
            return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 400)
        }
    }

    // milligrams (mg)
    func recommendedDailyCalcium() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if age < 4 {
            return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 700)
        } else if age < 9 {
            return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 1000)
        } else if age < 19 {
            return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 1300)
        } else if age < 51 {
            return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 1000)
        } else if age < 71 {
            if let sexObject = try? healthStore.biologicalSex(), sexObject.biologicalSex == .female {
                return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 1200)
            }
            return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 1000)
        } else {
            return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 1200)
        }
    }

    // percent (%)
    func recommendedDailyCarbohydratesPercentOfDietaryEnergy() -> ClosedRange<Double> {
        0.45...0.65
    }
}
