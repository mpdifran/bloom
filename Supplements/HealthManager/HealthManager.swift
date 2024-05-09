//
//  HealthManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation
import HealthKit

final class HealthManager: ObservableObject {
    static let shared = HealthManager()

    @Published var authStatus: HKAuthorizationRequestStatus = .unknown

    @Published var userInfo: UserInfoModel?

    private let healthStore = HKHealthStore()

    private init() { 
        checkAccess()
    }

    let types: Set = [
        HKQuantityType(.bodyMass)
    ]
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
                    await self.loadUserInfo()
                }
            }
        }
    }

    func requestAccess() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let allTypes: Set = [
            HKQuantityType(.bodyMass)
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: allTypes)
        } catch {
            fatalError("Usage description not specified")
        }

        checkAccess()
    }
}

extension HealthManager {

    func loadUserInfo() async {
        guard isAuthorized else { return }

        let bodyWeight = await fetchBodyWeight()

        await MainActor.run {
            self.userInfo = UserInfoModel(bodyWeight: bodyWeight?.quantity.doubleValue(for: .pound()))
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
}
