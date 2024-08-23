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

    func sexName() -> String? {
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

    func sex() -> HKBiologicalSex? {
        try? biologicalSex().biologicalSex
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

    func fetchSamples(
        for sampleType: HKSampleType,
        dateRange: DateRange
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: dateRange.start,
                end: dateRange.end,
                options: .strictStartDate
            )
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

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

    func fetchDailyAverageQuantity(
        for quantityTypeID: HKQuantityTypeIdentifier,
        unit: HKUnit,
        dateRange: DateRange,
        option: HKStatisticsOptions = .discreteAverage
    ) async throws -> HKQuantity {
        let quantity = try await fetchQuantity(
            for: quantityTypeID,
            dateRange: dateRange,
            option: option
        )
        let days = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1

        let average: Double
        if option == .cumulativeSum {
            average = quantity.doubleValue(for: unit) / Double(days)
        } else {
            average = quantity.doubleValue(for: unit)
        }

        return HKQuantity(unit: unit, doubleValue: average)
    }

    func fetchQuantity(
        for quantityTypeID: HKQuantityTypeIdentifier,
        dateRange: DateRange,
        option: HKStatisticsOptions = .discreteAverage
    ) async throws -> HKQuantity {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: dateRange.start,
                end: dateRange.end,
                options: .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: HKQuantityType(quantityTypeID),
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

    /// Queries a quantity type and groups values by time interval (specified by the interval parameter). `startDate` and `endDate` are automatically
    /// shifted to midnight on each day.
    func fetchCollatedQuantity(
        quantityTypeID: HKQuantityTypeIdentifier,
        unit: HKUnit,
        interval: DateComponents = DateComponents(day: 1),
        options: HKStatisticsOptions = [.cumulativeSum],
        dateRange: DateRange
    ) async throws -> [DateQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            let quantityType = HKQuantityType(quantityTypeID)

            let adjustedStartDate = Calendar.current.startOfDay(for: dateRange.start)
            let adjustedEndDate = Calendar.current.endOfDay(for: dateRange.end)

            let predicate = HKQuery.predicateForSamples(
                withStart: adjustedStartDate,
                end: adjustedEndDate,
                options: .strictStartDate
            )

            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options,
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
                        quantities.append(
                            DateQuantitySample(
                                date: statistics.startDate,
                                quantity: sum
                            )
                        )
                    }
                }
                continuation.resume(returning: quantities)
            }

            execute(query)
        }
    }

    func fetchAverageStatistics(
        quantityTypeID: HKQuantityTypeIdentifier,
        unit: HKUnit,
        interval: DateComponents = DateComponents(hour: 1),
        dateRange: DateRange
    ) async throws -> [DateQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            let quantityType = HKQuantityType(quantityTypeID)

            let predicate = HKQuery.predicateForSamples(
                withStart: dateRange.start,
                end: dateRange.end,
                options: .strictStartDate
            )

            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage],
                anchorDate: dateRange.start,
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

                var samples = [DateQuantitySample]()
                results.enumerateStatistics(from: dateRange.start, to: dateRange.end) { (statistics, stop) in
                    guard
                        let average = statistics.averageQuantity()
                    else { return }

                    samples.append(
                        DateQuantitySample(
                            date: statistics.startDate,
                            quantity: average
                        )
                    )
                }
                continuation.resume(returning: samples)
            }

            execute(query)
        }
    }

    func fetchNutritionalDailyAverage(
        for quantityTypeID: HKQuantityTypeIdentifier,
        unit: HKUnit,
        dateRange: DateRange
    ) async throws -> HKQuantity {
        let dailyAmounts = try await fetchCollatedQuantity(
            quantityTypeID: quantityTypeID,
            unit: unit,
            dateRange: dateRange
        )

        guard
            let earliestDate = dailyAmounts.min(keyPath: \.date),
            let latestDate = dailyAmounts.max(keyPath: \.date),
            let numberOfDays = Calendar.current.dateComponents([.day], from: earliestDate, to: latestDate).day
        else {
            return HKQuantity(unit: unit, doubleValue: 0)
        }

        // We add a day since the diff above doesn't include the current day
        let average = dailyAmounts.sum { sample in
            sample.quantity.doubleValue(for: unit)
        } / Double(numberOfDays + 1)

        return HKQuantity(unit: unit, doubleValue: average)
    }

    func fetchWorkouts(
        activityType: HKWorkoutActivityType? = nil,
        dateRange: DateRange
    ) async throws -> [HKWorkout] {
        let activityTypes = activityType.map({ [$0] }) ?? []
        return try await fetchWorkouts(activityTypes: activityTypes, dateRange: dateRange)
    }

    func fetchWorkouts(
        activityTypes: [HKWorkoutActivityType],
        dateRange: DateRange
    ) async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let basePredicate = HKQuery.predicateForSamples(
                withStart: dateRange.start,
                end: dateRange.end,
                options: .strictEndDate
            )
            let predicate: NSPredicate
            if activityTypes.isNotEmpty {
                let predicates = activityTypes.map { HKQuery.predicateForWorkouts(with: $0) }
                let activityPredicates = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, activityPredicates])
            } else {
                predicate = basePredicate
            }

            let sortDescriptors = [
                NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            ]

            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { (query, samples, error) in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(throwing: NSError(description: "HKSamples returned were the wrong type."))
                    return
                }

                continuation.resume(returning: workouts)
            }

            execute(query)
        }
    }

    func fetchWorkoutSummation(
        dateRange: DateRange
    ) async throws -> [WorkoutSummation] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: dateRange.start,
                end: dateRange.end,
                options: .strictEndDate
            )

            let sortDescriptors = [
                NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            ]

            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { (query, samples, error) in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let workoutSamples = samples as? [HKWorkout] else {
                    continuation.resume(throwing: NSError(description: "HKSamples returned were the wrong type."))
                    return
                }

                var calories = [HKWorkoutActivityType : Double]()
                var workoutCount = [HKWorkoutActivityType : Int]()

                for sample in workoutSamples {
                    guard
                        let activeBurned = sample.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .largeCalorie())
                    else { continue }

                    calories[sample.workoutActivityType, default: 0] += activeBurned
                    workoutCount[sample.workoutActivityType, default: 0] += 1
                }

                let summations = calories.keys.map { workoutType in
                    let calories = calories[workoutType, default: 0]
                    let count = workoutCount[workoutType, default: 0]

                    return WorkoutSummation(
                        activityType: workoutType,
                        totalCalories: calories,
                        instances: count
                    )
                }

                continuation.resume(returning: summations.sorted(by: { $0.totalCalories > $1.totalCalories }))
            }

            execute(query)
        }
    }
}

extension HKHealthStore {

    func observeChanges(
        sampleType: HKSampleType,
        dateRange: DateRange,
        frequency: HKUpdateFrequency = .hourly,
        performQuery: @escaping () async throws -> Void
    ) -> HKObserverQueryHandle {
        observeChanges(
            sampleTypes: [sampleType],
            dateRange: dateRange,
            frequency: frequency,
            performQuery: performQuery
        )
    }

    func observeChanges(
        sampleTypes: [HKSampleType],
        dateRange: DateRange,
        frequency: HKUpdateFrequency = .hourly,
        performQuery: @escaping () async throws -> Void
    ) -> HKObserverQueryHandle {
        var queries = [HKObserverQuery]()

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        for sampleType in sampleTypes {
            let observerQuery = HKObserverQuery(
                sampleType: sampleType,
                predicate: predicate
            ) { (query, completionHandler, error) in
                if let error {
                    print(error)
                    completionHandler()
                    return
                }

                Task {
                    do {
                        try await performQuery()
                    } catch {
                        print(error)
                    }
                    completionHandler()
                }
            }

            execute(observerQuery)
            queries.append(observerQuery)
        }

        return HKObserverQueryHandle(queries: queries, healthStore: self)
    }
}

extension HKHealthStore {

    func enableBackgroundDelivery(
        objectType: HKObjectType,
        frequency: HKUpdateFrequency = .immediate
    ) -> HKBackgroundDeliveryHandle {
        enableBackgroundDelivery(for: objectType, frequency: frequency) { success, error in
            if let error {
                print(error)
            }
        }
        return HKBackgroundDeliveryHandle(objectType: objectType, healthStore: self)
    }
}

// MARK: - Deprecated

extension HKHealthStore {

    @available(*, deprecated, message: "Use DateRange based query instead.")
    func fetchQuantity(
        for quantityTypeID: HKQuantityTypeIdentifier,
        pastMonths: Int,
        option: HKStatisticsOptions = .discreteAverage,
        unit: HKUnit
    ) async throws -> (Double, Int) {
        let start = Calendar.current.date(byAdding: .month, value: -pastMonths, to: .now)!
        let end = Date.now

        return try await fetchQuantity(
            for: quantityTypeID,
            start: start,
            end: end,
            option: option,
            unit: unit
        )
    }

    @available(*, deprecated, message: "Use DateRange based query instead.")
    func fetchQuantity(
        for quantityTypeID: HKQuantityTypeIdentifier,
        start: Date,
        end: Date,
        option: HKStatisticsOptions = .discreteAverage,
        unit: HKUnit
    ) async throws -> (Double, Int) {
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

    @available(*, deprecated, message: "Use DateRange based query instead.")
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
                quantityType: HKQuantityType(quantityTypeID),
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

    @available(*, deprecated, message: "Use DateRange based query instead.")
    func fetchNutritionalDailyAverage(
        for quantityTypeID: HKQuantityTypeIdentifier,
        startDate: Date,
        endDate: Date,
        unit: HKUnit
    ) async throws -> HKQuantity {
        let dailyAmounts = try await fetchCollectionQuantity(
            quantityTypeID: quantityTypeID,
            unit: unit,
            startDate: startDate,
            endDate: endDate
        )

        guard
            let earliestDate = dailyAmounts.min(keyPath: \.date),
            let latestDate = dailyAmounts.max(keyPath: \.date),
            let numberOfDays = Calendar.current.dateComponents([.day], from: earliestDate, to: latestDate).day
        else {
            return HKQuantity(unit: unit, doubleValue: 0)
        }

        // We add a day since the diff above doesn't include the current day
        let average = dailyAmounts.sum(keyPath: \.quantity) / Double(numberOfDays + 1)

        return HKQuantity(unit: unit, doubleValue: average)
    }

    @available(*, deprecated, message: "Create DateRange based method instead.")
    func fetchSamples(
        for quantityTypeID: HKQuantityTypeIdentifier,
        previousDays: Int
    ) async throws -> [HKSample] {
        let end = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -previousDays, to: end)!

        return try await fetchSamples(for: quantityTypeID, start: start, end: end)
    }

    @available(*, deprecated, message: "Create DateRange based method instead.")
    func fetchSamples(
        for sampleType: HKSampleType,
        previousDays: Int
    ) async throws -> [HKSample] {
        let end = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -previousDays, to: end)!

        return try await fetchSamples(for: sampleType, start: start, end: end)
    }

    @available(*, deprecated, message: "Create DateRange based method instead.")
    func fetchSamples(
        for quantityTypeID: HKQuantityTypeIdentifier,
        start: Date,
        end: Date
    ) async throws -> [HKSample] {
        try await fetchSamples(for: HKQuantityType(quantityTypeID), start: start, end: end)
    }

    @available(*, deprecated, message: "Create DateRange based method instead.")
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
}

extension HKHealthStore {

    /// Queries a quantity type and groups values by time interval (specified by the interval parameter). `startDate` and `endDate` are automatically
    /// shifted to midnight on each day.
    @available(*, deprecated, message: "Use fetchCollatedQuantity DateRange based method instead.")
    func fetchCollectionQuantity(
        quantityTypeID: HKQuantityTypeIdentifier,
        unit: HKUnit,
        interval: DateComponents = DateComponents(day: 1),
        startDate: Date,
        endDate: Date
    ) async throws -> [DateQuantitySampleLegacy] {
        try await withCheckedThrowingContinuation { continuation in
            let quantityType = HKQuantityType(quantityTypeID)

            let adjustedStartDate = Calendar.current.startOfDay(for: startDate)
            let adjustedEndDate = Calendar.current.endOfDay(for: endDate)

            let predicate = HKQuery.predicateForSamples(
                withStart: adjustedStartDate,
                end: adjustedEndDate,
                options: .strictStartDate
            )

            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
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

                var quantities = [DateQuantitySampleLegacy]()
                results.enumerateStatistics(from: adjustedStartDate, to: adjustedEndDate) { (statistics, stop) in
                    if let sum = statistics.sumQuantity() {
                        let quantity = sum.doubleValue(for: unit)
                        
                        quantities.append(
                            DateQuantitySampleLegacy(
                                date: statistics.startDate,
                                quantity: quantity,
                                unit: unit.unitString
                            )
                        )
                    }
                }
                continuation.resume(returning: quantities)
            }

            execute(query)
        }
    }

    @available(*, deprecated, message: "Add a DateRange based method before using this.")
    func fetchMinMaxStatistics(
        quantityTypeID: HKQuantityTypeIdentifier,
        unit: HKUnit,
        interval: DateComponents = DateComponents(hour: 1),
        startDate: Date,
        endDate: Date
    ) async throws -> [DateMinMaxQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            let quantityType = HKQuantityType(quantityTypeID)

            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: [.discreteMin, .discreteMax],
                anchorDate: startDate,
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

                var samples = [DateMinMaxQuantitySample]()
                results.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
                    guard 
                        let min = statistics.minimumQuantity(),
                        let max = statistics.maximumQuantity()
                    else { return }

                    let minQuantity = min.doubleValue(for: unit)
                    let maxQuantity = max.doubleValue(for: unit)

                    samples.append(
                        DateMinMaxQuantitySample(
                            date: statistics.startDate,
                            minQuantity: minQuantity,
                            maxQuantity: maxQuantity,
                            unit: unit.unitString
                        )
                    )
                }
                continuation.resume(returning: samples)
            }

            execute(query)
        }
    }

    @available(*, deprecated, message: "Use DateRange based method instead.")
    func fetchAverageStatistics(
        quantityTypeID: HKQuantityTypeIdentifier,
        unit: HKUnit,
        interval: DateComponents = DateComponents(hour: 1),
        startDate: Date,
        endDate: Date
    ) async throws -> [DateAverageQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            let quantityType = HKQuantityType(quantityTypeID)

            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage],
                anchorDate: startDate,
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

                var samples = [DateAverageQuantitySample]()
                results.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
                    guard
                        let average = statistics.averageQuantity()
                    else { return }

                    let averageQuantity = average.doubleValue(for: unit)

                    samples.append(
                        DateAverageQuantitySample(
                            date: statistics.startDate,
                            averageQuantity: averageQuantity,
                            unit: unit.unitString
                        )
                    )
                }
                continuation.resume(returning: samples)
            }

            execute(query)
        }
    }
}

extension HKHealthStore {

    @available(*, deprecated, message: "Use DateRange based method instead.")
    func fetchWorkoutSummaries(
        startDate: Date,
        endDate: Date,
        activityType: HKWorkoutActivityType? = nil
    ) async throws -> [WorkoutSummary] {
        try await withCheckedThrowingContinuation { continuation in
            let basePredicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictEndDate
            )
            let predicate: NSPredicate
            if let activityType {
                let activityPredicate = HKQuery.predicateForWorkouts(with: activityType)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, activityPredicate])
            } else {
                predicate = basePredicate
            }

            let sortDescriptors = [
                NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            ]

            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { (query, samples, error) in
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
                        let activeBurned = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .largeCalorie())
                    else { return nil }

                    let totalDistance = workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0

                    return WorkoutSummary(
                        activity: workout.workoutActivityType.name,
                        startDate: workout.startDate,
                        durationSeconds: workout.duration,
                        caloriesBurned: activeBurned,
                        distance: totalDistance
                    )
                }

                continuation.resume(returning: summaries)
            }

            execute(query)
        }
    }

    @available(*, deprecated, message: "Use the DateRange based method instead")
    func fetchWorkoutSummation(
        startDate: Date,
        endDate: Date
    ) async throws -> [WorkoutSummation] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictEndDate
            )

            let sortDescriptors = [
                NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            ]

            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { (query, samples, error) in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let workoutSamples = samples as? [HKWorkout] else {
                    continuation.resume(throwing: NSError(description: "HKSamples returned were the wrong type."))
                    return
                }

                var calories = [HKWorkoutActivityType : Double]()
                var workoutCount = [HKWorkoutActivityType : Int]()

                for sample in workoutSamples {
                    guard
                        let activeBurned = sample.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .largeCalorie())
                    else { continue }

                    calories[sample.workoutActivityType, default: 0] += activeBurned
                    workoutCount[sample.workoutActivityType, default: 0] += 1
                }

                let summations = calories.keys.map { workoutType in
                    let calories = calories[workoutType, default: 0]
                    let count = workoutCount[workoutType, default: 0]

                    return WorkoutSummation(
                        activityType: workoutType,
                        totalCalories: calories,
                        instances: count
                    )
                }

                continuation.resume(returning: summations.sorted(by: { $0.totalCalories > $1.totalCalories }))
            }

            execute(query)
        }
    }
}

extension HKHealthStore {

    @available(*, deprecated, message: "Use the other method instead")
    func observeChanges(
        sampleType: HKSampleType,
        dateRange: DateRange? = nil,
        frequency: HKUpdateFrequency = .hourly,
        backgroundUpdates: Bool = false,
        performQuery: @escaping () async throws -> Void
    ) throws {
        try observeChanges(
            sampleTypes: [sampleType],
            dateRange: dateRange,
            frequency: frequency,
            backgroundUpdates: backgroundUpdates,
            performQuery: performQuery
        )
    }

    @available(*, deprecated, message: "Use the other method instead")
    func observeChanges(
        sampleTypes: [HKSampleType],
        dateRange: DateRange? = nil,
        frequency: HKUpdateFrequency = .hourly,
        backgroundUpdates: Bool = false,
        performQuery: @escaping () async throws -> Void
    ) throws {
        Task {
            for sampleType in sampleTypes {
                if backgroundUpdates {
                    do {
                        try await enableBackgroundDelivery(for: sampleType, frequency: frequency)
                    } catch {
                        throw error
                    }
                }

                let predicate: NSPredicate?
                if let dateRange {
                    predicate = HKQuery.predicateForSamples(
                        withStart: dateRange.start,
                        end: dateRange.end,
                        options: .strictStartDate
                    )
                } else {
                    predicate = nil
                }

                let observerQuery = HKObserverQuery(
                    sampleType: sampleType,
                    predicate: predicate
                ) { (query, completionHandler, error) in
                    if let error {
                        print(error)
                        completionHandler()
                        return
                    }

                    Task {
                        do {
                            try await performQuery()
                        } catch {
                            print(error)
                        }
                        completionHandler()
                    }
                }

                execute(observerQuery)
            }
        }
    }
}
