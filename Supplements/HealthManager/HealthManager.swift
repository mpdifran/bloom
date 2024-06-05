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

    @Published var userInfo: UserInfoModel?

    private let healthStore = HKHealthStore()
    private let throttler = Throttler(timeInterval: 600)

    private var sleepDataListenerTask: Task<Void, Error>? = nil
    private var sleepQueryAnchor: HKQueryAnchor? {
        didSet {
            do {
                if let anchor = sleepQueryAnchor {
                    let anchorData = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                    UserDefaults.standard.set(anchorData, forKey: "sleepQueryAnchor")
                } else {
                    UserDefaults.standard.set(nil, forKey: "sleepQueryAnchor")
                }
            } catch {
                print(error)
            }
        }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: "sleepQueryAnchor") {
            do {
                let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
                self.sleepQueryAnchor = anchor
            } catch {
                print(error)
            }
        }

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
        HKObjectType.quantityType(forIdentifier: .timeInDaylight)!,
        HKCategoryType(.sleepAnalysis),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.bodyFatPercentage),
        HKObjectType.workoutType(),
        HKObjectType.categoryType(forIdentifier: .mindfulSession)!
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

//    func checkAccess() {
//        healthStore.getRequestStatusForAuthorization(toShare: [], read: types) { authStatus, error in
//            DispatchQueue.main.async {
//                self.authStatus = authStatus
//                Task {
//                    try? await self.loadUserInfo()
//                }
//            }
//        }
//    }

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
                fatalError("Usage description not specified")
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

        let sleepAnalysis = await fetchDailySleepAnalysis()

        let activeEnergy = await fetchActiveEnergy().map {
            QuantityModel(amount: $0.0, kind: .average, unit: "calories", periodDays: $0.1)
        }

        let bodyFatPercentage = await fetchBodyFatPercentage().map {
            QuantityModel(amount: $0.0, kind: .average, unit: "percent", periodDays: $0.1)
        }

        let workoutSummaries = await fetchWorkoutSummaryLastTwoWeeks()

        let meditationMinutes = await fetchMeditationMinutes().map {
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
            self.userInfo = UserInfoModel(
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
                sleepAnalysis: sleepAnalysis,
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

    func fetchRestingHeartRate() async -> [HeartRateSample] {
        do {
            let samples = try await healthStore.fetchSamples(for: .restingHeartRate, previousDays: 7)

            return samples.compactMap { sample in
                sample as? HKQuantitySample
            }.map { sample in
                let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                return HeartRateSample(
                    date: sample.startDate,
                    value: value,
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

    func fetchMeditationMinutes() async -> (Double, Int)? {
        do {
            let meditationType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
            let samples = try await healthStore.fetchSamples(for: meditationType, previousDays: 7)

            let meditationMinutes = samples.reduce(0) { (total, sample) -> Double in
                total + sample.endDate.timeIntervalSince(sample.startDate) / 60
            }

            return (meditationMinutes / 7, 7)
        } catch {
            print(error)
        }
        return nil
    }

    func fetchDailySleepAnalysis(period: Int = 7) async -> [SleepAnalysis] {
        do {
            let sampleType = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
            let end = Date.now
            let start = Calendar.current.sleepStartDate(previousDays: period, endDate: end)
            let samples = try await healthStore.fetchSamples(for: sampleType, start: start, end: end) as? [HKCategorySample] ?? []

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

            return groupedSamples.compactMap { sampleGroup -> SleepAnalysis? in
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
                    return nil
                }

                return SleepAnalysis(
                    startDate: startDate,
                    endDate: endDate,
                    deepSleepMinutes: deepSleepTime / 60,
                    coreSleepMinutes: coreSleepTime / 60,
                    remSleepMinutes: remSleepTime / 60,
                    awakeSleepMinutes: awakeSleepTime / 60
                )
            }
        } catch {
            print("Sleep Analysis Error: \(error)")
        }
        return []
    }

    func fetchSleepAnalysis() async -> SleepAggregates? {
        do {
            let period = 7
            let sampleType = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
            let samples = try await healthStore.fetchSamples(for: sampleType, previousDays: period)
            let end = Calendar.current.date(byAdding: .day, value: -period, to: .now)!
            let start = Calendar.current.date(byAdding: .day, value: -period, to: end)!
            let previousSamples = try await healthStore.fetchSamples(for: sampleType, start: start, end: end)

            let sums = sumSleepStages(in: samples)
            let previousSums = sumSleepStages(in: previousSamples)

            return SleepAggregates(
                remSleep: .init(
                    currentPeriodAmount: sums.totalREM / Double(period),
                    previousPeriodAmount: previousSums.totalREM / Double(period),
                    unit: "seconds",
                    periodDays: period,
                    kind: .average
                ),
                deepSleep: .init(
                    currentPeriodAmount: sums.totalDeep / Double(period),
                    previousPeriodAmount: previousSums.totalDeep / Double(period),
                    unit: "seconds",
                    periodDays: period,
                    kind: .average
                ),
                coreSleep: .init(
                    currentPeriodAmount: sums.totalCore / Double(period),
                    previousPeriodAmount: previousSums.totalCore / Double(period),
                    unit: "seconds",
                    periodDays: period,
                    kind: .average
                ),
                asleepTotal: .init(
                    currentPeriodAmount: sums.totalAsleep / Double(period),
                    previousPeriodAmount: previousSums.totalAsleep / Double(period),
                    unit: "seconds",
                    periodDays: period,
                    kind: .average
                ),
                awake: .init(
                    currentPeriodAmount: sums.totalAwake / Double(period),
                    previousPeriodAmount: previousSums.totalAwake / Double(period),
                    unit: "seconds",
                    periodDays: period,
                    kind: .average
                )
            )
        } catch {
            print(error)
        }
        return nil
    }

    func sumSleepStages(in samples: [HKSample]) -> SleepStageSum {
        var sums = SleepStageSum()

        for sample in samples {
            guard
                let categorySample = sample as? HKCategorySample,
                let state = HKCategoryValueSleepAnalysis(rawValue: categorySample.value)
            else { continue }

            switch state {
            case .inBed:
                break
            case .asleepUnspecified:
                sums.totalAsleep += categorySample.timeInterval
            case .asleep:
                sums.totalAsleep += categorySample.timeInterval
            case .awake:
                sums.totalAwake += categorySample.timeInterval
            case .asleepCore:
                sums.totalCore += categorySample.timeInterval
            case .asleepDeep:
                sums.totalDeep += categorySample.timeInterval
            case .asleepREM:
                sums.totalREM += categorySample.timeInterval
            @unknown default:
                break
            }
        }

        return sums
    }
}

struct SleepStageSum {
    var totalREM: Double = 0
    var totalDeep: Double = 0
    var totalCore: Double = 0
    var totalAsleep: Double = 0
    var totalAwake: Double = 0
}

extension HealthManager {

    func observeSleepData() {
        guard let sampleType = HKSampleType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("Cannot observe sleep data")
            return
        }
        
        sleepDataListenerTask = Task.detached { [weak self, healthStore] in
            do {
                for try await result in healthStore.observeChanges(sampleType: sampleType, anchor: self?.sleepQueryAnchor) {
                    let (samples, anchor) = result

                    if samples.isNotEmpty, self?.sleepQueryAnchor != nil {
                        let categories = samples.compactMap({ $0 as? HKCategorySample }).compactMap({ $0.sleepCategory?.name })
                        print("Anchor Query notified of sleep categories:")
                        print(categories)

                        await NotificationManager.shared.sendGoodMorningNotification()
                    }

                    print("Sleep anchor updated")
                    self?.sleepQueryAnchor = anchor
                }
            } catch {
                print(error)
            }
        }
    }
}
