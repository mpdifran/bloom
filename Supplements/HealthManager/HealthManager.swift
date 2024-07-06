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
    @Published var userInfoModel: UserInfoModel?

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
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
        HKObjectType.characteristicType(forIdentifier: .bloodType)!,
        HKObjectType.activitySummaryType(),
        HKQuantityType(.appleExerciseTime),
        HKQuantityType(.stepCount),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .vo2Max)!,
        HKQuantityType(.timeInDaylight),
        HKCategoryType(.sleepAnalysis),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.bodyFatPercentage),
        HKObjectType.workoutType(),
        HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure)!
    ]
    // body fat percentage
    // BMI
    // respiratory rate
    // blood oxygen
    // double support time
    // walking steadiness
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
                fatalError(error.localizedDescription)
            }
        }
        try? await checkAccess()
        try? await loadUserInfo()
    }
}

extension HealthManager {

    func loadUserInfo() async throws {
        guard isAuthorized else { return }

        print("Loading Health Data")

        let bodyWeight = await fetchBodyWeight().map {
            QuantityModel(amount: $0.quantity.doubleValue(for: .pound()), kind: .latestValue, unit: "pounds", periodDays: nil)
        }

        let avgExerciseMinQuantity = await fetchExerciseMinutes().map {
            QuantityModel(amount: $0.0, kind: .average, unit: "minutes", periodDays: $0.1)
        }

        let stepsQuantity = await fetchAverageSteps().map {
            QuantityModel(amount: $0.0, kind: .average, unit: "count", periodDays: $0.1)
        }

        let hrvAverage = await fetchHRV().map {
            QuantityModel(amount: $0.0, kind: .average, unit: "milliseconds", periodDays: $0.1)
        }

        let restingHeartRate = await fetchRestingHeartRate()

        let vO2Max = await fetchVO2Max().map {
            QuantityModel(amount: $0, kind: .latestValue, unit: "mL/min·kg", periodDays: nil)
        }

        let timeInDaylight = await fetchAverageTimeInDaylight().map {
            QuantityModel(amount: $0.0, kind: .average, unit: "minutes", periodDays: $0.1)
        }

        let activeEnergy = await fetchActiveEnergy().map {
            QuantityModel(amount: $0.0, kind: .average, unit: "calories", periodDays: $0.1)
        }

        let bodyFatPercentage = await fetchBodyFatPercentage().map {
            QuantityModel(amount: $0.0, kind: .average, unit: "percent", periodDays: $0.1)
        }

        let workoutSummaries = await fetchWorkoutSummaryLastTwoWeeks()

        let meditationMinutes = await fetchAverageMeditationMinutes().map {
            QuantityModel(amount: $0.0, kind: .average, unit: "minutes", periodDays: $0.1)
        }

        let name = ProfileViewModel.shared.name.isEmpty ? nil : ProfileViewModel.shared.name
        let location: LocationModel?
        if let currentLocation = LocationManager.shared.currentLocation {
            location = .init(
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude
            )
        } else {
            location = nil
        }

        await MainActor.run {
            self.userInfoModel = UserInfoModel(
                name: name,
                location: location,
                age: healthStore.age(),
                sex: healthStore.sex(),
                bloodType: healthStore.typeOfBlood(),
                bodyWeightPounds: bodyWeight,
                dailyExerciseMinutes: avgExerciseMinQuantity,
                dailySteps: stepsQuantity,
                dailyHeartRateVariability: hrvAverage,
                restingHeartRate: restingHeartRate,
                vO2Max: vO2Max,
                timeInDaylight: timeInDaylight,
                sleepAnalysis: sleepAnalysis7Days ?? [],
                activeEnergy: activeEnergy,
                bodyFatPercentage: bodyFatPercentage,
                workouts: workoutSummaries,
                meditationMinutes: meditationMinutes
            )
        }
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
                let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
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

    func fetchVO2Max() async -> Double? {
        do {
            let sample = try await healthStore.fetchLatestSample(for: .vo2Max)
            return (sample as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "mL/min·kg"))
        } catch {
            print(error)
        }
        return nil
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
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.date(byAdding: .day, value: -periodDays, to: endDate) else {
                return []
            }

            return try await healthStore.fetchCollectionQuantity(
                quantityTypeID: .timeInDaylight,
                unit: HKUnit.minute(),
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchActiveEnergy() async -> (Double, Int)? {
        do {
            return try await healthStore.fetchQuantity(
                for: .activeEnergyBurned,
                pastMonths: 1,
                option: .cumulativeSum,
                unit: .smallCalorie()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchWorkoutSummaryLastTwoWeeks() async -> [WorkoutSummary] {
        do {
            return try await healthStore.fetchWorkoutSummaries(recentDays: 14)
        } catch {
            print(error)
        }
        return []
    }

    func fetchBodyFatPercentage() async -> (Double, Int)? {
        do {
            return try await healthStore.fetchQuantity(
                for: .bodyFatPercentage,
                pastMonths: 1,
                option: .discreteAverage,
                unit: .percent()
            )
        } catch {
            print(error)
        }
        return nil
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
}

// MARK: - Sleep

extension HealthManager {

    func observeSleepData() {
        guard sleepDataListenerTask == nil else { return }

        sleepDataListenerTask = Task.detached { [weak self, healthStore] in
            do {
                for try await samples in healthStore.observeAsyncChanges(sampleType: HKCategoryType(.sleepAnalysis), performQuery: {
                    try await self?.fetchSleepSamples(period: 30) ?? []
                }) {
                    let lastPreviousSleepAnalysis = self?.sleepAnalysis30Days?.last
                    await self?.publishSleepAnalysis(samples: samples)
                    let lastSleepAnalysis = self?.sleepAnalysis30Days?.last

                    if lastSleepAnalysis?.endDate != lastPreviousSleepAnalysis?.endDate && lastPreviousSleepAnalysis != nil {
                        // We've triggered from new data, not from app launch
                        await NotificationManager.shared.sendGoodMorningNotification(delay: 60 * 5)
                    }
                }
            } catch {
                print(error)
            }
        }
    }

    func fetchSleepSamples(period: Int = 7) async throws -> [HKSample] {
        let sampleType = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
        let end = Date.now
        let start = Calendar.current.sleepStartDate(previousDays: period, endDate: end)
        return try await healthStore.fetchSamples(for: sampleType, start: start, end: end)
    }

    func publishSleepAnalysis(samples: [HKSample]) async {
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

            let timePeriod: Int = 10

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

            let analysis = SleepAnalysis(
                startDate: startDate,
                endDate: endDate,
                deepSleepMinutes: deepSleepTime / 60,
                coreSleepMinutes: coreSleepTime / 60,
                remSleepMinutes: remSleepTime / 60,
                awakeSleepMinutes: awakeSleepTime / 60,
                environmentalSoundLevels: soundLevelDataPoints,
                heartRate: heartRateDataPoints
            )
            sleepAnalysis.append(analysis)
        }

        let result = sleepAnalysis

        await MainActor.run {
            self.sleepAnalysis30Days = result
            self.sleepAnalysis7Days = Array(result.suffix(7))
        }
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
}
