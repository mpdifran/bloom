//
//  HealthManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import SwiftUI
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

    @AppStorage("HealthManager.isPregnant") var isPregnant: Bool = false
    @AppStorage("HealthManager.isBreastfeeding") var isBreastfeeding: Bool = false

    let healthStore = HKHealthStore()
    private let throttler = Throttler(timeInterval: 600)

    private var sleepDataListenerTask: Task<Void, Error>? = nil

    private init() {
        Task {
            try? await checkAccess()
        }
    }

    let bodyMeasurementTypes = [
        HKQuantityType(.bodyMass),
        HKCharacteristicType(.dateOfBirth),
        HKCharacteristicType(.biologicalSex),
        HKQuantityType(.bodyFatPercentage)
    ]

    let activityTypes = [
        HKObjectType.activitySummaryType(),
        HKQuantityType(.appleExerciseTime),
        HKQuantityType(.stepCount),
        HKQuantityType(.basalEnergyBurned),
        HKQuantityType(.activeEnergyBurned),
        HKObjectType.workoutType(),
        HKQuantityType(.distanceWalkingRunning)
    ]

    let heartTypes = [
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.vo2Max),
        HKQuantityType(.heartRate),
        HKQuantityType(.bloodPressureSystolic),
        HKQuantityType(.bloodPressureDiastolic),
        HKQuantityType(.heartRateRecoveryOneMinute),
    ]

    let sleepTypes = [
        HKCategoryType(.sleepAnalysis),
        HKQuantityType(.environmentalAudioExposure),
        HKQuantityType(.respiratoryRate),
        HKQuantityType(.appleSleepingWristTemperature),
    ]

    let nutritionTypes = [
        HKQuantityType(.dietaryBiotin),
        HKQuantityType(.dietaryCaffeine),
        HKQuantityType(.dietaryCalcium),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryChloride),
        HKQuantityType(.dietaryCholesterol),
        HKQuantityType(.dietaryChromium),
        HKQuantityType(.dietaryCopper),
        HKQuantityType(.dietaryFatMonounsaturated),
        HKQuantityType(.dietaryFatPolyunsaturated),
        HKQuantityType(.dietaryFatSaturated),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietaryFiber),
        HKQuantityType(.dietaryFolate),
        HKQuantityType(.dietaryIodine),
        HKQuantityType(.dietaryIron),
        HKQuantityType(.dietaryMagnesium),
        HKQuantityType(.dietaryManganese),
        HKQuantityType(.dietaryMolybdenum),
        HKQuantityType(.dietaryNiacin),
        HKQuantityType(.dietaryPantothenicAcid),
        HKQuantityType(.dietaryPhosphorus),
        HKQuantityType(.dietaryPotassium),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryRiboflavin),
        HKQuantityType(.dietarySelenium),
        HKQuantityType(.dietarySodium),
        HKQuantityType(.dietarySugar),
        HKQuantityType(.dietaryThiamin),
        HKQuantityType(.dietaryVitaminA),
        HKQuantityType(.dietaryVitaminB12),
        HKQuantityType(.dietaryVitaminB6),
        HKQuantityType(.dietaryVitaminC),
        HKQuantityType(.dietaryVitaminD),
        HKQuantityType(.dietaryVitaminE),
        HKQuantityType(.dietaryVitaminK),
        HKQuantityType(.dietaryWater),
        HKQuantityType(.dietaryZinc)
    ]

    let otherTypes = [
        HKQuantityType(.timeInDaylight),
        HKCategoryType(.mindfulSession),
        HKCategoryType(.appleWalkingSteadinessEvent),
        HKQuantityType(.sixMinuteWalkTestDistance),
        HKQuantityType(.walkingDoubleSupportPercentage),
        HKQuantityType(.dietaryEnergyConsumed)
    ]
}

extension HealthManager {

    var isAuthorized: Bool {
        authStatus == .unnecessary
    }

    func types() -> Set<HKObjectType> {
        var set = Set<HKObjectType>()

        bodyMeasurementTypes.forEach { set.insert($0) }
        activityTypes.forEach { set.insert($0) }
        heartTypes.forEach { set.insert($0) }
        sleepTypes.forEach { set.insert($0) }
        nutritionTypes.forEach { set.insert($0) }
        otherTypes.forEach { set.insert($0) }

        return set
    }

    func checkAccess() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.getRequestStatusForAuthorization(toShare: [], read: types()) { authStatus, error in
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
                try await healthStore.requestAuthorization(toShare: [], read: types())
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

    func sexName() -> String? {
        healthStore.sexName()
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

    func fetchNetEnergy(numPrevDays: Int = 7) async -> [DateQuantitySample] {
        let endDate = Date.now

        guard let startDate = Calendar.current.date(byAdding: .day, value: -numPrevDays, to: endDate) else { return [] }

        let basal = try? await healthStore.fetchCollectionQuantity(
            quantityTypeID: .basalEnergyBurned,
            unit: .largeCalorie(),
            startDate: startDate,
            endDate: endDate
        )

        let active = try? await healthStore.fetchCollectionQuantity(
            quantityTypeID: .activeEnergyBurned,
            unit: .largeCalorie(),
            startDate: startDate,
            endDate: endDate
        )

        let dietary = try? await healthStore.fetchCollectionQuantity(
            quantityTypeID: .dietaryEnergyConsumed,
            unit: .largeCalorie(),
            startDate: startDate,
            endDate: endDate
        )

        var samples = [DateQuantitySample]()

        for basalSample in basal ?? [] {
            guard 
                let activeEnergy = active?.first(where: { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) })?.quantity,
                let dietaryEnergy = dietary?.first(where: { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) })?.quantity
            else {
                continue
            }

            let netEnergy = dietaryEnergy - basalSample.quantity - activeEnergy

            samples.append(.init(date: basalSample.date, quantity: netEnergy, unit: HKUnit.largeCalorie().unitString))
        }

        return samples
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

    func fetchBodyFatPercentageSamples() async -> [DateAverageQuantitySample] {
        let endDate = Date()

        guard let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) else { return [] }

        do {
            return try await healthStore.fetchAverageStatistics(
                quantityTypeID: .bodyFatPercentage,
                unit: .percent(),
                interval: .init(day: 1),
                startDate: startDate,
                endDate: endDate
            )
        } catch { }
        return []
    }

    func fetchAverageBodyFatPercentage(numPastMonths: Int = 0) async -> (Double, Int)? {
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

    func fetchNutritionalDailyQuantities(
        quantityTypeID: HKQuantityTypeIdentifier,
        unit: HKUnit,
        numPrevDays: Int
    ) async -> [DateQuantitySample] {
        let endDate = Date.now

        guard let startDate = Calendar.current.date(byAdding: .day, value: -numPrevDays, to: endDate) else { return [] }

        return (try? await healthStore.fetchCollectionQuantity(
            quantityTypeID: quantityTypeID,
            unit: unit,
            startDate: startDate,
            endDate: endDate
        )) ?? []
    }

    func fetchDietaryNutritionPercentageThisWeek(
        quantityTypeID: HKQuantityTypeIdentifier,
        caloriesPerGram: Double
    ) async -> Double {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.startOfWeek(for: endDate) else { return 0 }

            let quantity = try await healthStore.fetchQuantity(
                for: quantityTypeID,
                start: startDate,
                end: endDate
            )
            let dietaryEnergy = try await healthStore.fetchQuantity(
                for: .dietaryEnergyConsumed,
                start: startDate,
                end: endDate
            )

            return (quantity.doubleValue(for: .gram()) * caloriesPerGram) / dietaryEnergy.doubleValue(for: .largeCalorie())
        } catch {
            print(error)
        }
        return 0
    }

    func fetchNutritionDailyAverageThisWeek(quantityTypeID: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.startOfWeek(for: endDate) else { return 0 }

            return try await healthStore.fetchNutritionalDailyAverage(
                for: quantityTypeID,
                startDate: startDate,
                endDate: endDate,
                unit: unit
            ).doubleValue(for: unit)
        } catch {
            print(error)
        }
        return 0
    }

    func fetchNutritionMonthlySummary() async -> NutritionMonthlySummary? {
        let endDate = Date.now

        guard let midDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate),
              let startDate = Calendar.current.date(byAdding: .month, value: -1, to: midDate)
        else {
            return nil
        }

        let bodyWeight = await fetchBodyWeight()
        let thisMonth = await fetchNutritionMonthlySummaryDetails(startDate: midDate, endDate: endDate)
        let lastMonth = await fetchNutritionMonthlySummaryDetails(startDate: startDate, endDate: midDate)

        return NutritionMonthlySummary(
            bodyWeight: bodyWeight,
            details: thisMonth,
            lastMonthDetails: lastMonth
        )
    }

    func fetchNutritionMonthlySummaryDetails(startDate: Date, endDate: Date) async -> NutritionMonthlySummary.Details {
        let basalEnergyBurned = try? await healthStore.fetchQuantity(
            for: .basalEnergyBurned,
            start: startDate,
            end: endDate,
            option: .cumulativeSum,
            unit: .largeCalorie()
        )

        let activeEnergyBurned = try? await healthStore.fetchQuantity(
            for: .activeEnergyBurned,
            start: startDate,
            end: endDate,
            option: .cumulativeSum,
            unit: .largeCalorie()
        )

        let dietaryEnergy = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryEnergyConsumed,
            startDate: startDate,
            endDate: endDate,
            unit: .largeCalorie()
        )

        let protein = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryProtein,
            startDate: startDate,
            endDate: endDate,
            unit: .gram()
        )

        let carbohydrates = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryCarbohydrates,
            startDate: startDate,
            endDate: endDate,
            unit: .gram()
        )

        let fat = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryFatTotal,
            startDate: startDate,
            endDate: endDate,
            unit: .gram()
        )

        let sugar = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietarySugar,
            startDate: startDate,
            endDate: endDate,
            unit: .gram()
        )

        let caffeine = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryCaffeine,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let vitaminA = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminA,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .micro)
        )

        let vitaminC = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminC,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let vitaminD = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminD,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .micro)
        )

        let vitaminE = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminE,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let vitaminB6 = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminB6,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let vitaminB12 = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminB12,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .micro)
        )

        let calcium = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryCalcium,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let iron = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryIron,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let magnesium = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryMagnesium,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let potassium = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryPotassium,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let zinc = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryZinc,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        return .init(
            basalEnergyBurned: basalEnergyBurned.map { HKQuantity(unit: .largeCalorie(), doubleValue: $0.0) },
            activeEnergyBurned: activeEnergyBurned.map { HKQuantity(unit: .largeCalorie(), doubleValue: $0.0) },
            dietaryEnergy: dietaryEnergy,
            averageProtein: protein,
            averageCarbohydrates: carbohydrates,
            averageFat: fat,
            averageSugar: sugar,
            averageCaffeine: caffeine,
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
            averageZinc: zinc
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
            try healthStore.observeChanges(sampleType: HKCategoryType(.sleepAnalysis), frequency: .immediate, backgroundUpdates: true) { [weak self, healthStore] in
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

    /// - note: https://www.healthline.com/health/exercise-fitness/ideal-body-fat-percentage
    func goalBodyFatPercentage() -> (Double, Double, Double, Double, Double)? {
        guard let sexObject = try? healthStore.biologicalSex() else { return nil }

        switch sexObject.biologicalSex {
        case .female:
            return (0.14, 0.21, 0.25, 0.32, 0.50)
        case .male:
            return (0.06, 0.14, 0.18, 0.25, 0.43)
        default:
            return nil
        }
    }

    func bloodPressureCategory(systolic: Double , diastolic: Double) -> BloodPressureCategory {
        if systolic > 180 || diastolic > 110 {
            return .hypertensiveCrisis
        } else if systolic > 160 || diastolic > 100 {
            return .hypertensionStage2
        } else if systolic > 140 || diastolic > 90 {
            return .hypertensionStage1
        } else if systolic > 120 || diastolic > 80 {
            return .elevated
        } else if systolic > 90 || diastolic > 60 {
            return .normal
        } else {
            return .low
        }
    }
}

// MARK: Nutitional Intake

extension HealthManager {

    /// unit: micrograms (mcg)
    /// - note: https://ods.od.nih.gov/factsheets/Biotin-HealthProfessional/
    func adequateDailyIntakeForBiotin() -> HKQuantity? {
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

    /// unit: milligrams (mg)
    /// - note: https://www.opss.org/article/caffeine-performance
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

    /// unit: percent (%)
    /// - note: https://www.mayoclinic.org/healthy-lifestyle/nutrition-and-healthy-eating/in-depth/carbohydrates/art-20045705
    func recommendedDailyCarbohydratesPercentOfDietaryEnergy() -> ClosedRange<Double> {
        0.45...0.65
    }

    /// unit: grams
    /// - note: https://nutritionsource.hsph.harvard.edu/chloride/
    func adequateDailyIntakeForChloride() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if age < 14 {
            return nil
        } else if age < 51 {
            return HKQuantity(unit: .gram(), doubleValue: 2.3)
        } else if age < 71 {
            return HKQuantity(unit: .gram(), doubleValue: 2)
        } else {
            return HKQuantity(unit: .gram(), doubleValue: 1.8)
        }
    }

    /// unit: mg/dL
    /// - note: https://www.healthline.com/health/high-cholesterol/levels-by-age
    func recommendedDailyMaxCholesterol() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if age < 20 {
            return HKQuantity(unit: .mgPerDL(), doubleValue: 170)
        } else {
            return HKQuantity(unit: .mgPerDL(), doubleValue: 200)
        }
    }

    /// unit: mcg
    /// - note: https://ods.od.nih.gov/factsheets/chromium-Consumer/
    func adequateDailyIntakeForChromium() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            if age < 19 {
                return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 29)
            }
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 30)
        }
        if isBreastfeeding {
            if age < 19 {
                return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 44)
            }
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 45)
        }

        if age < 4 {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 11)
        } else if age < 9 {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 15)
        } else if age < 14 {
            if healthStore.sex() == .male {
                return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 25)
            }
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 21)
        } else if age < 19 {
            if healthStore.sex() == .male {
                return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 35)
            }
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 24)
        } else if age < 51 {
            if healthStore.sex() == .male {
                return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 35)
            }
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 25)
        } else {
            if healthStore.sex() == .male {
                return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 30)
            }
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 20)
        }
    }

    /// unit: mcg
    /// - note: https://ods.od.nih.gov/factsheets/Copper-Consumer/
    func recommendedDailyIntakeForCopper() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isBreastfeeding {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 1300...10000)
        }
        if isPregnant {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 1000...10000)
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 340...1000)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 440...3000)
        } else if age < 14 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 700...5000)
        } else if age < 19 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 890...8000)
        } else {
           return HKQuantityRange(unit: .gramUnit(with: .micro), range: 900...10000)
        }
    }

    /// unit: %
    /// - note: https://www.healthline.com/nutrition/how-much-fat-to-eat
    func recommendedDailyFatPercentOfDietaryEnergy() -> ClosedRange<Double> {
        0.2...0.35
    }

    /// unit: grams
    ///  - note: https://www.mayoclinic.org/healthy-lifestyle/nutrition-and-healthy-eating/in-depth/fiber/art-20043983
    func adequateDailyIntakeForFiber() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if age < 50 {
            if healthStore.sex() == .female {
                return HKQuantity(unit: .gram(), doubleValue: 25)
            }
            return HKQuantity(unit: .gram(), doubleValue: 38)
        } else {
            if healthStore.sex() == .female {
                return HKQuantity(unit: .gram(), doubleValue: 21)
            }
            return HKQuantity(unit: .gram(), doubleValue: 30)
        }
    }

    /// unit: mcg
    /// - note: https://ods.od.nih.gov/factsheets/Folate-Consumer/
    func recommendedDailyIntakeForFolate() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 600...1000)
        }
        if isBreastfeeding {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 500...1000)
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 150...300)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 200...400)
        } else if age < 14 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 300...600)
        } else if age < 19 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 400...800)
        } else {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 400...1000)
        }
    }

    /// unit: %
    /// - note: https://www.medicalnewstoday.com/articles/protein-intake#calculating-requirements
    func recommendedDailyProteinPercentOfDietaryEnergy() -> ClosedRange<Double> {
        0.1...0.35
    }

    /// unit: gram
    /// - note: https://www.medicalnewstoday.com/articles/protein-intake#calculating-requirements
    func adequateDailyIntakeForProtein() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if healthStore.sex() == .female {
            if age < 4 {
                return HKQuantity(unit: .gram(), doubleValue: 13)
            } else if age < 9 {
                return HKQuantity(unit: .gram(), doubleValue: 19)
            } else if age < 14 {
                return HKQuantity(unit: .gram(), doubleValue: 34)
            } else {
                return HKQuantity(unit: .gram(), doubleValue: 46)
            }
        } else {
            if age < 4 {
                return HKQuantity(unit: .gram(), doubleValue: 13)
            } else if age < 9 {
                return HKQuantity(unit: .gram(), doubleValue: 19)
            } else if age < 14 {
                return HKQuantity(unit: .gram(), doubleValue: 34)
            } else if age < 19 {
                return HKQuantity(unit: .gram(), doubleValue: 52)
            } else {
                return HKQuantity(unit: .gram(), doubleValue: 56)
            }
        }
    }

    /// unit: g
    /// - note: https://www.medicalnewstoday.com/articles/324673#recommended-limits
    func recommendedMaxDailyIntakeForSugar() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if age < 19 {
            return HKQuantity(unit: .gram(), doubleValue: 25)
        }
        if healthStore.sex() == .female {
            return HKQuantity(unit: .gram(), doubleValue: 25)
        }
        return HKQuantity(unit: .gram(), doubleValue: 38)
    }

    /// unit: mcg
    /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
    func recommendedDailyIntakeForVitaminA() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .micro), range: 750...2800)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .micro), range: 770...3000)
            }
        }
        if isBreastfeeding {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .micro), range: 1200...2800)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .micro), range: 1300...3000)
            }
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 300...600)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 400...900)
        } else if age < 14 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 600...1700)
        } else if age < 19 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .micro), range: 700...2800)
            }
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 900...2800)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .micro), range: 700...3000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 900...3000)
        }
    }

    /// unit: mg
    /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html#tbl2
    func recommendedDailyIntakeForVitaminB6() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.9...80)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.9...100)
            }
        }
        if isBreastfeeding {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2...80)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2...100)
            }
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 0.5...30)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 0.6...40)
        } else if age < 14 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1...60)
        } else if age < 19 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.2...80)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.3...80)
        } else if age < 51 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.3...100)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.5...100)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.7...100)
        }
    }

    /// unit: mcg
    /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
    func recommendedMinDailyIntakeForVitaminB12() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 2.6)
        }
        if isBreastfeeding {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 2.8)
        }

        if age < 4 {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 0.9)
        } else if age < 9 {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 1.2)
        } else if age < 14 {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 1.8)
        } else {
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 2.4)
        }
    }

    /// unit: mg
    /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html#tbl2
    func recommendedDailyIntakeForVitaminC() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 80...1800)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 85...2000)
            }
        }
        if isBreastfeeding {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 115...1800)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 120...2000)
            }
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...400)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 25...650)
        } else if age < 14 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 45...1200)
        } else if age < 19 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 65...1800)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 75...1800)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 75...2000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 90...2000)
        }
    }

    /// unit: mcg
    /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
    func recommendedDailyIntakeForVitaminD() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant || isBreastfeeding {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 15...100)
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 15...63)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 15...75)
        } else if age < 70 {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 15...100)
        } else {
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 20...100)
        }
    }

    /// unit: mg
    /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
    func recommendedDailyIntakeForVitaminE() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...800)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...1000)
            }
        }
        if isBreastfeeding {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 19...800)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 19...1000)
            }
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 6...200)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 7...300)
        } else if age < 14 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...600)
        } else if age < 19 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...800)
        } else {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...1000)
        }
    }

    /// unit: mg
    /// - note: https://ods.od.nih.gov/factsheets/calcium-HealthProfessional/
    func recommendedIntakeForCalcium() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant || isBreastfeeding {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1300...3000)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1000...2500)
            }
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 700...2500)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1000...2500)
        } else if age < 14 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1300...3000)
        } else if age < 19 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1300...3000)
        } else if age < 51 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1000...2500)
        } else if age < 70 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1200...2000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1000...2000)
        } else {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1200...2000)
        }
    }

    /// unit: mg
    /// - note: https://ods.od.nih.gov/factsheets/Iron-HealthProfessional/
    func recommendedDailyIntakeForIron() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 27...45)
        }
        if isBreastfeeding {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 10...45)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 9...45)
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 7...40)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 10...40)
        } else if age < 14 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...40)
        } else if age < 19 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...45)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...45)
        } else if age < 51 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 18...45)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...45)
        } else {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...45)
        }
    }

    /// Magnesium from supplements specifically should be limited. Magnesium found in food is ok, and there's not really a UL for it.
    /// unit: mg
    /// - note: https://ods.od.nih.gov/factsheets/magnesium-healthprofessional/
    func recommendedDailyIntakeForMagnesium() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 400...750)
            } else if age < 31 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 350...700)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 360...710)
            }
        }
        if isBreastfeeding {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 360...710)
            } else if age < 31 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 310...660)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 320...670)
            }
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 80...145)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 130...240)
        } else if age < 14 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 240...590)
        } else if age < 19 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 360...710)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 410...760)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 320...670)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 420...770)
        }
    }

    /// There is no recommended UL, so we're just picking an arbitrary number. There is no risk to this since any amount of Potassium is safe.
    /// unit: mg
    /// - note: https://ods.od.nih.gov/factsheets/Potassium-HealthProfessional/
    func recommendedDailyIntakeForPotassium() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2600...10000)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2900...10000)
            }
        }
        if isBreastfeeding {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2500...10000)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2800...10000)
            }
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2000...10000)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2300...10000)
        } else if age < 14 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2300...10000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2500...10000)
        } else if age < 19 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2300...10000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3000...10000)
        } else if age < 51 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2600...10000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3400...10000)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2600...10000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3400...10000)
        }
    }

    /// unit: mg
    /// - note: https://ods.od.nih.gov/factsheets/zinc-healthprofessional/
    func recommendedDailyIntakeForZinc() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

        if isPregnant {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 12...34)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...40)
            }
        }
        if isBreastfeeding {
            if age < 19 {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 13...34)
            } else {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 12...40)
            }
        }

        if age < 4 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3...7)
        } else if age < 9 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 5...12)
        } else if age < 14 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...23)
        } else if age < 19 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 9...34)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...34)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...40)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...40)
        }
    }
}
