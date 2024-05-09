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
        HKQuantityType(.appleExerciseTime)
    ]
    // active energy
    // steps
    // sleep
    // exercise min
    // vO2 max
    // body fat percentage
    // BMI
    // HRV
    // resting heart rate
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

        let bodyWeight = await fetchBodyWeight()
        let avgExerciseMin: Double?
        do {
            avgExerciseMin = try await fetchExerciseMinutes()
        } catch {
            print(error)
            avgExerciseMin = nil
        }

        let avgExerciseMinQuantity = avgExerciseMin.map {
            QuantityModel(amount: $0, kind: .average, periodDays: 1)
        }

        await MainActor.run {
            self.userInfo = UserInfoModel(
                age: healthStore.age(),
                sex: healthStore.sex(),
                bodyWeight: bodyWeight?.quantity.doubleValue(for: .pound()),
                averageExerciseMin: avgExerciseMinQuantity
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

    func fetchExerciseMinutes() async throws -> Double {
        try await healthStore.sumQuantity(
            for: .appleExerciseTime,
            pastMonths: 1,
            unit: .minute()
        )
    }
}
