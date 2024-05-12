//
//  HealthManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation
import HealthKit
import AppFoundations

final class HealthManager: ObservableObject {
    static let shared = HealthManager()

    @Published var authStatus: HKAuthorizationRequestStatus = .unknown

    @Published var userInfo: UserInfoModel?

    private let healthStore = HKHealthStore()

    private init() { 
        DispatchQueue.main.async { [weak self] in
            self?.checkAccess()
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
        HKObjectType.quantityType(forIdentifier: .timeInDaylight)!
    ]
    // active energy
    // sleep
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

    func checkAccess() {
        healthStore.getRequestStatusForAuthorization(toShare: [], read: types) { authStatus, error in
            DispatchQueue.main.async {
                self.authStatus = authStatus
                Task {
                    try? await self.loadUserInfo()
                }
            }
        }
    }

    func requestAccess() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
        } catch {
            fatalError("Usage description not specified")
        }

        checkAccess()
    }
}

extension HealthManager {

    func loadUserInfo() async throws {
        guard isAuthorized else { return }

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

        let timeInDaylight = await fetchTimeInDaylight().map {
            QuantityModel(amount: $0.0, kind: .average, unit: "minutes", periodDays: $0.1)
        }

        await MainActor.run {
            self.userInfo = UserInfoModel(
                age: healthStore.age(),
                sex: healthStore.sex(),
                bloodType: healthStore.typeOfBlood(),
                bodyWeightPounds: bodyWeight,
                dailyExerciseMinutes: avgExerciseMinQuantity,
                dailySteps: stepsQuantity,
                dailyHeartRateVariability: hrvAverage,
                restingHeartRate: restingHeartRate,
                vO2Max: vO2Max,
                timeInDaylight: timeInDaylight
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

    func fetchRestingHeartRate() async -> [Double] {
        do {
            let samples = try await healthStore.fetchSamples(for: .restingHeartRate, previousDays: 7)

            return samples.compactMap { sample in
                sample as? HKQuantitySample
            }.map { sample in
                sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
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

    func fetchTimeInDaylight() async -> (Double, Int)? {
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
}
