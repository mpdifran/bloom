//
//  HealthStore+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import Foundation
import HealthKit

extension HKHealthStore {

    func fetchQuantity(
        for quantityTypeID: HKQuantityTypeIdentifier,
        pastMonths: Int,
        option: HKStatisticsOptions = .discreteAverage,
        unit: HKUnit
    ) async throws -> (Double, Int) {
        let start = Calendar.current.date(byAdding: .month, value: -pastMonths, to: .now)!
        let end = Date.now

        let quantity = try await fetchQuantity(
            for: quantityTypeID,
            start: start,
            end: end,
            option: option
        )
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1

        let average: Double
        if option == .cumulativeSum {
            average = quantity.doubleValue(for: unit) / Double(days)
        } else {
            average = quantity.doubleValue(for: unit)
        }

        return (average, days)
    }

    func fetchQuantity(
        for quantityTypeID: HKQuantityTypeIdentifier,
        start: Date,
        end: Date,
        option: HKStatisticsOptions = .discreteAverage
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

                let quantity: HKQuantity?
                switch option {
                case .cumulativeSum:
                    quantity = result?.sumQuantity()
                case .discreteAverage:
                    quantity = result?.averageQuantity()
                default:
                    quantity = nil
                }

                guard let result = result, let quantity else {
                    continuation.resume(throwing: NSError(description: "Something went wrong"))
                    return
                }

                continuation.resume(returning: quantity)
            }
            execute(query)
        }
    }
}

extension HKHealthStore {

    func age() -> Int? {
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

    func typeOfBlood() -> String? {
        do {
            let blood = try bloodType()

            switch blood.bloodType {
            case .notSet:
                return "Not Set"
            case .aPositive:
                return "A Positive"
            case .aNegative:
                return "A Negative"
            case .bPositive:
                return "B Positive"
            case .bNegative:
                return "B Negative"
            case .abPositive:
                return "AB Positive"
            case .abNegative:
                return "AB Negative"
            case .oPositive:
                return "O Positive"
            case .oNegative:
                return "O Negative"
            @unknown default:
                return "Unknown"
            }
        } catch {
            print(error)
        }
        return nil
    }
}
