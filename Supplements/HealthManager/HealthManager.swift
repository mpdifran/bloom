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
        checkAccess()
    }

    let types: Set = [
        HKQuantityType(.bodyMass),
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
        HKObjectType.characteristicType(forIdentifier: .bloodType)!,
        HKObjectType.activitySummaryType()
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

        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
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
            self.userInfo = UserInfoModel(
                bodyWeight: bodyWeight?.quantity.doubleValue(for: .pound())
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
        try await withCheckedThrowingContinuation { continuation in
            // Define the predicate for the last month
            let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            let endDate = Date()
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

            // Define the statistics options (here we are getting the sum of exercise time)
            let statisticsOptions: HKStatisticsOptions = .cumulativeSum

            // Define the statistics query
            let query = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
                                          quantitySamplePredicate: predicate,
                                          options: statisticsOptions) { (query, result, error) in
                guard let result = result, let sum = result.sumQuantity() else {
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: NSError(description: "Something went wrong"))
                    }
                    return
                }

                // Convert the sum from seconds to minutes
                let sumInMinutes = sum.doubleValue(for: HKUnit.minute())

                // Calculate the average minutes per day
                let daysInMonth = Calendar.current.range(of: .day, in: .month, for: startDate)!.count
                let averageMinutesPerDay = sumInMinutes / Double(daysInMonth)

                continuation.resume(returning: averageMinutesPerDay)
            }

            // Execute the query
            healthStore.execute(query)
        }
    }
}
