//
//  HealthStore+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import Foundation
import HealthKit
import AppFoundations

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

                guard let quantity else {
                    continuation.resume(throwing: NSError(description: "Could not get quantity."))
                    return
                }

                continuation.resume(returning: quantity)
            }
            execute(query)
        }
    }

    func fetchSamples(
        for quantityTypeID: HKQuantityTypeIdentifier,
        previousDays: Int
    ) async throws -> [HKSample] {
        let end = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -previousDays, to: end)!

        return try await fetchSamples(for: quantityTypeID, start: start, end: end)
    }

    func fetchSamples(
        for sampleType: HKSampleType,
        previousDays: Int
    ) async throws -> [HKSample] {
        let end = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -previousDays, to: end)!

        return try await fetchSamples(for: sampleType, start: start, end: end)
    }

    func fetchSamples(
        for quantityTypeID: HKQuantityTypeIdentifier,
        start: Date,
        end: Date
    ) async throws -> [HKSample] {
        guard let sampleType = HKSampleType.quantityType(forIdentifier: quantityTypeID) else {
            throw NSError(description: "Sample type not available")
        }

        return try await fetchSamples(for: sampleType, start: start, end: end)
    }

    func fetchSamples(
        for sampleType: HKSampleType,
        start: Date,
        end: Date
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: start,
                end: end,
                options: .strictStartDate
            )
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

            let sampleQuery = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { (query, samples, error) in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples else {
                    continuation.resume(throwing: NSError(description: "No samples returned"))
                    return
                }

                continuation.resume(returning: samples)
            }
            execute(sampleQuery)
        }
    }

    func fetchLatestSample(for quantityTypeID: HKQuantityTypeIdentifier) async throws -> HKSample {
        try await withCheckedThrowingContinuation { continuation in
            guard let sampleType = HKSampleType.quantityType(forIdentifier: quantityTypeID) else {
                let error = NSError(description: "Sample type not available")
                continuation.resume(throwing: error)
                return
            }

            let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]

            let sampleQuery = HKSampleQuery(
                sampleType: sampleType,
                predicate: nil,
                limit: 1,
                sortDescriptors: sortDescriptors
            ) { query, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first else {
                    continuation.resume(throwing: NSError(description: "No samples returned"))
                    return
                }

                continuation.resume(returning: sample)
            }
            execute(sampleQuery)
        }
    }
}

extension HKHealthStore {

    /// Queries a quantity type and groups values by time interval (specified by the interval parameter). `startDate` and `endDate` are automatically
    /// shifted to midnight on each day.
    func fetchCollectionQuantity(
        quantityTypeID: HKQuantityTypeIdentifier,
        unit: HKUnit,
        interval: DateComponents = DateComponents(day: 1),
        startDate: Date,
        endDate: Date
    ) async throws -> [DateQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            guard let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeID) else {
                let error = NSError(description: "Quantity type not available")
                continuation.resume(throwing: error)
                return
            }

            let adjustedStartDate = Calendar.current.startOfDay(for: startDate)
            let adjustedEndDate = Calendar.current.endOfDay(for: endDate)

            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: nil,
                options: [.cumulativeSum],
                anchorDate: adjustedStartDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { query, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results else {
                    continuation.resume(returning: [])
                    return
                }

                var quantities = [DateQuantitySample]()
                results.enumerateStatistics(from: adjustedStartDate, to: adjustedEndDate) { (statistics, stop) in
                    if let sum = statistics.sumQuantity() {
                        let quantity = sum.doubleValue(for: unit)

                        quantities.append(.init(date: statistics.startDate, quantity: quantity))
                    }
                }
                continuation.resume(returning: quantities)
            }

            execute(query)
        }
    }
}

extension HKHealthStore {

    func fetchWorkoutSummaries(recentDays: Int) async throws -> [WorkoutSummary] {
        try await withCheckedThrowingContinuation { continuation in
            let workoutType = HKObjectType.workoutType()

            let endDate = Date.now
            guard let startDate = Calendar.current.date(byAdding: .day, value: -recentDays, to: endDate) else {
                continuation.resume(throwing: NSError(description: "The calendar messed up for some reason..."))
                return
            }

            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictEndDate
            )

            let sortDescriptors = [
                NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            ]

            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) {
                query,
                samples,
                error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workoutSamples = samples as? [HKWorkout] else {
                    continuation.resume(throwing: NSError(description: "HKSamples returned were the wrong type."))
                    return
                }
                
                let summaries = workoutSamples.compactMap { workout -> WorkoutSummary? in
                    guard
                        let activeBurned = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .smallCalorie())
                    else { return nil }

                    let energyBurned = WorkoutSummary.EnergyBurned(
                        value: activeBurned,
                        units: "calories"
                    )

                    return WorkoutSummary(
                        activity: workout.workoutActivityType.name,
                        startDate: workout.startDate,
                        durationSeconds: workout.duration,
                        energyBurned: energyBurned
                    )
                }

                continuation.resume(returning: summaries)
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

extension HKHealthStore {

    func enableImmediateBackgrounDelivery(sampleType: HKSampleType) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    func observeChanges(sampleType: HKSampleType, anchor: HKQueryAnchor?) -> AsyncThrowingStream<([HKSample], HKQueryAnchor?), Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard try await enableImmediateBackgrounDelivery(sampleType: sampleType) else {
                        continuation.finish()
                        return
                    }
                } catch {
                    continuation.finish(throwing: error)
                }

                print("Starting observation of \(sampleType)")

                let query = HKAnchoredObjectQuery(
                    type: sampleType,
                    predicate: nil,
                    anchor: anchor,
                    limit: HKObjectQueryNoLimit
                ) { (query, samples, deletedObjects, anchor, error) in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    if let samples {
                        continuation.yield((samples, anchor))
                    }
                }
                execute(query)
            }
        }
    }
}
