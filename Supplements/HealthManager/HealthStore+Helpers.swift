//
//  HealthStore+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import Foundation
import HealthKit

extension HKHealthStore {

    func sumQuantity(
        for quantityTypeID: HKQuantityTypeIdentifier,
        pastMonths: Int,
        option: HKStatisticsOptions = .cumulativeSum,
        unit: HKUnit
    ) async throws -> Double {
        let start = Calendar.current.date(byAdding: .month, value: -pastMonths, to: .now)!
        let end = Date.now

        let quantity = try await sumQuantity(
            for: quantityTypeID,
            start: start,
            end: end,
            option: option
        )

        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1

        let sumInUnits = quantity.doubleValue(for: unit)

        return sumInUnits / Double(days)
    }

    func sumQuantity(
        for quantityTypeID: HKQuantityTypeIdentifier,
        start: Date,
        end: Date,
        option: HKStatisticsOptions = .cumulativeSum
    ) async throws -> HKQuantity {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: start,
                end: end,
                options: .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: HKQuantityType.quantityType(
                    forIdentifier: quantityTypeID
                )!,
                quantitySamplePredicate: predicate,
                options: option
            ) { (query, result, error) in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(throwing: NSError(description: "Something went wrong"))
                    return
                }

                continuation.resume(returning: sum)
            }
            execute(query)
        }
    }
}

extension HKHealthStore {

    func age() -> Int? {
        let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!

        do {
            let dateOfBirthComponents = try dateOfBirthComponents()
            guard let dateOfBirth = Calendar.current.date(from: dateOfBirthComponents) else { return nil }

            return Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year
        } catch {
            print(error)
        }
        return nil
    }

    func sex() -> String? {
        do {
            let biologicalSexObject = try biologicalSex()

            switch biologicalSexObject.biologicalSex {
            case .notSet:
                return "Not Set"
            case .female:
                return "Female"
            case .male:
                return "Male"
            case .other:
                return "Other"
            @unknown default:
                return "Unknown"
            }
        } catch {
            print(error)
        }
        return nil
    }
}
