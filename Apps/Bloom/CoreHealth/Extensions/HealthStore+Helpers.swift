//
//  HealthStore+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import Foundation
@preconcurrency import HealthKit
import AppFoundations
import BloomFoundation
import CoreLocation

public extension HKHealthStore {

  func getRequestStatusForAuthorization(
    toShare typesToShare: Set<HKSampleType>,
    read typesToRead: Set<HKObjectType>
  ) async throws -> HKAuthorizationRequestStatus {
    try await withCheckedThrowingContinuation { continuation in
      getRequestStatusForAuthorization(toShare: typesToShare, read: typesToRead) { authStatus, error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: authStatus)
        }
      }
    }
  }
}

public extension HKHealthStore {

  func birthday() -> Date? {
    do {
      let dateOfBirthComponents = try dateOfBirthComponents()
      return Calendar.current.date(from: dateOfBirthComponents)
    } catch {
      print(error)
    }
    return nil
  }

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

  func height() async -> HKQuantity? {
    await HealthStoreFetcher.shared.fetchLatestSample(for: .height)?.quantity
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

public extension HKHealthStore {

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
    dateRange: DateRange,
    additionalPredicates: [NSPredicate] = []
  ) async throws -> [HKSample] {
    try await withCheckedThrowingContinuation { continuation in
      let datePredicate = HKQuery.predicateForSamples(
        withStart: dateRange.start,
        end: dateRange.end,
        options: .strictStartDate
      )
      let predicates = [datePredicate] + additionalPredicates
      let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
      let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

      let sampleQuery = HKSampleQuery(
        sampleType: sampleType,
        predicate: combinedPredicate,
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
        results.enumerateStatistics(from: adjustedStartDate, to: adjustedEndDate) { statistics, _ in
          // Use the correct accessor based on options
          let quantity: HKQuantity?
          if options.contains(.discreteMin) {
            quantity = statistics.minimumQuantity()
          } else if options.contains(.discreteMax) {
            quantity = statistics.maximumQuantity()
          } else if options.contains(.discreteAverage) {
            quantity = statistics.averageQuantity()
          } else {
            quantity = statistics.sumQuantity()
          }

          if let quantity {
            quantities.append(
              DateQuantitySample(
                date: statistics.startDate,
                quantity: quantity
              )
            )
          } else if options.contains(.cumulativeSum) {
            // For cumulative sum, append 0 if no data (preserves old behavior)
            quantities.append(
              DateQuantitySample(
                date: statistics.startDate,
                quantity: HKQuantity(unit: unit, doubleValue: 0)
              )
            )
          }
          // For discrete options (min/max/average), skip days with no data
        }
        //                if !quantities.contains(where: { Calendar.current.isDateInToday($0.date) }) && dateRange.containsTodayDate() {
        //                    quantities.append(
        //                        DateQuantitySample(
        //                            date: Calendar.current.startOfDay(for: .now),
        //                            quantity: HKQuantity(unit: unit, doubleValue: 0)
        //                        )
        //                    )
        //                }
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
    dateRange: DateRange,
    limit: Int? = nil
  ) async throws -> [HKWorkout] {
    let activityTypes = activityType.map({ [$0] }) ?? []
    return try await fetchWorkouts(
      activityTypes: activityTypes,
      dateRange: dateRange,
      limit: limit
    )
  }

  func fetchWorkouts(
    activityTypes: [HKWorkoutActivityType],
    dateRange: DateRange,
    limit: Int? = nil
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
        limit: limit ?? HKObjectQueryNoLimit,
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

  func fetchCollatedWorkouts(
    activityTypes: [HKWorkoutActivityType],
    dateRange: DateRange
  ) async throws -> [DateCollatedWorkouts] {
    let workouts = try await fetchWorkouts(
      activityTypes: activityTypes,
      dateRange: dateRange
    )

    var collatedWorkouts = [Date: [HKWorkout]]()

    for workout in workouts {
      if let existingDate = collatedWorkouts.keys.first(where: {
        return Calendar.current.isDate($0, inSameDayAs: workout.startDate)
      }) {
        collatedWorkouts[existingDate, default: []].append(workout)
      } else {
        let referenceDate = Calendar.current.startOfDay(for: workout.startDate)
        collatedWorkouts[referenceDate, default: []].append(workout)
      }
    }

    var result = [DateCollatedWorkouts]()
    Calendar.current.iterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
      if
        let key = collatedWorkouts.keys.first(where: { Calendar.current.isDate($0, inSameDayAs: date) }),
        let workouts = collatedWorkouts[key]
      {
        result.append(DateCollatedWorkouts(date: date, workouts: workouts))
      } else {
        result.append(DateCollatedWorkouts(date: date, workouts: []))
      }
    }

    return result.sorted(keyPath: \.date)
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

        var calories = [HKWorkoutActivityType: Double]()
        var workoutCount = [HKWorkoutActivityType: Int]()

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

  func fetchWorkoutRoutes(for workout: HKWorkout) -> AsyncStream<[WorkoutRoute]> {

    @Sendable
    func fetchLocations(for workoutRoute: HKWorkoutRoute) async throws -> [CLLocation] {
      try await withCheckedThrowingContinuation { continuation in
        let buffer = LocationBuffer()

        let query = HKWorkoutRouteQuery(route: workoutRoute) { (_, locations, done, error) in
          if let error {
            continuation.resume(throwing: error)
            return
          }

          // HKWorkoutRouteQuery delivers batches serially on its own queue, so append
          // synchronously. (Previously this used fire-and-forget Tasks, which raced with the
          // `done` read — a single-batch route, e.g. a short/indoor workout, could resume with
          // zero locations before its one batch was appended.)
          if let locations {
            buffer.append(locations)
          }

          if done {
            continuation.resume(returning: buffer.locations)
          }
        }

        execute(query)
      }
    }

    return AsyncStream { continuation in

      @Sendable
      func updateHandler(samples: [HKSample]?, error: Error?) async {
        if let error {
          print(error)
          continuation.finish()
          return
        }

        guard let workoutRoutes = samples as? [HKWorkoutRoute] else { return }

        var routes = [WorkoutRoute]()
        for route in workoutRoutes {
          do {
            let locations = try await fetchLocations(for: route)
            routes.append(WorkoutRoute(locations: locations))
          } catch {
            print("Error fetching locations for route: \(error)")
          }
        }
        continuation.yield(routes)
      }

      let predicate = HKQuery.predicateForObjects(from: workout)

      let query = HKAnchoredObjectQuery(
        type: HKSeriesType.workoutRoute(),
        predicate: predicate,
        anchor: nil,
        limit: HKObjectQueryNoLimit
      ) { (query, samples, deletedObjects, anchor, error) in
        Task {
          await updateHandler(samples: samples, error: error)
        }
      }

      query.updateHandler = { (query, samples, deletedObjects, anchor, error) in
        Task {
          await updateHandler(samples: samples, error: error)
        }
      }

      execute(query)
    }
  }
}

private final class LocationBuffer: @unchecked Sendable {
  private let lock = NSLock()
  private var storage = [CLLocation]()

  func append(_ newLocations: [CLLocation]) {
    lock.lock()
    storage.append(contentsOf: newLocations)
    lock.unlock()
  }

  var locations: [CLLocation] {
    lock.lock()
    defer { lock.unlock() }
    return storage
  }
}

public extension HKHealthStore {

  func observeChanges(
    sampleType: HKSampleType,
    startDate: Date,
    performQuery: @escaping @Sendable () async throws -> Void
  ) -> HKObserverQueryHandle {
    observeChanges(
      sampleTypes: [sampleType],
      startDate: startDate,
      performQuery: performQuery
    )
  }

  func observeChanges(
    sampleTypes: [HKSampleType],
    startDate: Date,
    performQuery: @escaping @Sendable () async throws -> Void
  ) -> HKObserverQueryHandle {
    var queries = [HKObserverQuery]()

    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: nil,
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

        Task { @Sendable in
          do {
            try await performQuery()
          } catch {
            print(error)
          }
        }
        completionHandler()
      }

      execute(observerQuery)
      queries.append(observerQuery)
    }

    return HKObserverQueryHandle(queries: queries, healthStore: self)
  }
}

public extension HKHealthStore {

  func enableBackgroundDelivery(
    objectType: HKObjectType,
    frequency: HKUpdateFrequency = .immediate
  ) {
    enableBackgroundDelivery(for: objectType, frequency: frequency) { success, error in
      if let error {
        print(error)
      }
    }
  }
}
