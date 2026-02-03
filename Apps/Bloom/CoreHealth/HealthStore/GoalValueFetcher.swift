//
//  GoalValueFetcher.swift
//  CoreHealth
//
//  Created by Claude Code on 2026-02-03.
//

import Foundation
@preconcurrency import HealthKit
import BloomFoundation

/// Fetches goal values from HealthKit for any goal type.
/// This centralizes the logic for fetching goal progress data, making it available
/// to both the iOS app and watchOS widgets.
public actor GoalValueFetcher {
  public static let shared = GoalValueFetcher()

  private init() {}

  // MARK: - Public API

  /// Fetches the total quantity for a goal from HealthKit
  /// - Parameters:
  ///   - goalId: The goal identifier (matches TargetMetric.rawValue)
  ///   - dateRange: The date range to query
  /// - Returns: The current value as HKQuantity
  public func fetchTotalQuantity(goalId: String, dateRange: DateRange) async -> HKQuantity {
    let defaultUnit = defaultUnit(for: goalId)
    let defaultQuantity = HKQuantity(unit: defaultUnit, doubleValue: 0)

    switch goalId {
    case "none":
      return defaultQuantity

    case "calories":
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryEnergyConsumed, dateRange: dateRange) ?? defaultQuantity

    case "proteinIntake":
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryProtein, dateRange: dateRange) ?? defaultQuantity

    case "waterIntake":
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryWater, dateRange: dateRange) ?? defaultQuantity

    case "fiberIntake":
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryFiber, dateRange: dateRange) ?? defaultQuantity

    case "timeInDaylight":
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .timeInDaylight, dateRange: dateRange) ?? defaultQuantity

    case "meditationMinutes":
      return await HealthStoreFetcher.shared.fetchTotalMeditationMinutes(dateRange: dateRange)

    case "exerciseMinutes":
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .appleExerciseTime, dateRange: dateRange) ?? defaultQuantity

    case "workoutMinutes":
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(dateRange: dateRange)
      let totalDuration = workouts.sum { $0.duration }
      return HKQuantity(unit: .second(), doubleValue: totalDuration)

    case "stepCount":
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .stepCount, dateRange: dateRange) ?? defaultQuantity

    case "walkingRunningDistance":
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .distanceWalkingRunning, dateRange: dateRange) ?? defaultQuantity

    case "runDistance":
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityType: .running, dateRange: dateRange)
      let totalDistance = workouts.sum { workout in
        workout.totalDistanceWalkingRunning?.doubleValue(for: defaultUnit) ?? 0
      }
      return HKQuantity(unit: defaultUnit, doubleValue: totalDistance)

    case "runDuration":
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityType: .running, dateRange: dateRange)
      let totalDuration = workouts.sum { $0.duration }
      return HKQuantity(unit: .second(), doubleValue: totalDuration)

    case "bikeDistance":
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityType: .cycling, dateRange: dateRange)
      let totalDistance = workouts.sum { workout in
        workout.totalDistanceCycling?.doubleValue(for: defaultUnit) ?? 0
      }
      return HKQuantity(unit: defaultUnit, doubleValue: totalDistance)

    case "bikeDuration":
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityType: .cycling, dateRange: dateRange)
      let totalDuration = workouts.sum { $0.duration }
      return HKQuantity(unit: .second(), doubleValue: totalDuration)

    case "mobilityAndFlexibilityDuration":
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityTypes: .mobilityAndFlexibilityTypes, dateRange: dateRange)
      let totalDuration = workouts.sum { $0.duration }
      return HKQuantity(unit: .second(), doubleValue: totalDuration)

    case "strengthTrainingDuration":
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityTypes: .strengthTrainingTypes, dateRange: dateRange)
      let totalDuration = workouts.sum { $0.duration }
      return HKQuantity(unit: .second(), doubleValue: totalDuration)

    case "cardioDuration":
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityTypes: .cardioTypes, dateRange: dateRange)
      let totalDuration = workouts.sum { $0.duration }
      return HKQuantity(unit: .second(), doubleValue: totalDuration)

    case "highIntensityIntervalTrainingDuration":
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityTypes: .highIntensityIntervalTrainingTypes, dateRange: dateRange)
      let totalDuration = workouts.sum { $0.duration }
      return HKQuantity(unit: .second(), doubleValue: totalDuration)

    case "targetHeartRateZone1":
      let reports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let distribution = reports.generateOverallDistribution()
      return distribution.zone1

    case "targetHeartRateZone2":
      let reports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let distribution = reports.generateOverallDistribution()
      return distribution.zone2

    case "targetHeartRateZone3":
      let reports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let distribution = reports.generateOverallDistribution()
      return distribution.zone3

    case "targetHeartRateZone4":
      let reports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let distribution = reports.generateOverallDistribution()
      return distribution.zone4

    case "targetHeartRateZone5":
      let reports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let distribution = reports.generateOverallDistribution()
      return distribution.zone5

    default:
      return defaultQuantity
    }
  }

  /// Fetches the current value for a goal from HealthKit using a time period string
  /// - Parameters:
  ///   - goalId: The goal identifier (matches TargetMetric.rawValue)
  ///   - timePeriod: "daily", "weekly", "monthly", or "yearly"
  /// - Returns: The current value as a Double in the goal's default unit
  public func fetchCurrentValue(goalId: String, timePeriod: String) async -> Double {
    let dateRange = calculateDateRange(for: timePeriod)
    let quantity = await fetchTotalQuantity(goalId: goalId, dateRange: dateRange)
    let unit = defaultUnit(for: goalId)
    return quantity.doubleValue(for: unit)
  }

  // MARK: - Default Units

  /// Returns the default unit for a goal type
  public func defaultUnit(for goalId: String) -> HKUnit {
    switch goalId {
    case "none":
      return .count()
    case "calories":
      return .largeCalorie()
    case "proteinIntake":
      return .gram()
    case "waterIntake":
      return .literUnit(with: .milli)
    case "fiberIntake":
      return .gram()
    case "timeInDaylight":
      return .minute()
    case "meditationMinutes":
      return .minute()
    case "exerciseMinutes", "workoutMinutes":
      return .minute()
    case "stepCount":
      return .count()
    case "walkingRunningDistance":
      return .meterUnit(with: .kilo)
    case "runDistance":
      return .meterUnit(with: .kilo)
    case "runDuration":
      return .minute()
    case "bikeDistance":
      return .meterUnit(with: .kilo)
    case "bikeDuration":
      return .minute()
    case "mobilityAndFlexibilityDuration", "strengthTrainingDuration", "cardioDuration", "highIntensityIntervalTrainingDuration":
      return .minute()
    case "targetHeartRateZone1", "targetHeartRateZone2", "targetHeartRateZone3", "targetHeartRateZone4", "targetHeartRateZone5":
      return .minute()
    default:
      return .count()
    }
  }

  // MARK: - Date Range Calculation

  /// Calculates the date range for a time period
  private func calculateDateRange(for timePeriod: String) -> DateRange {
    let calendar = Calendar.current
    let now = Date()

    switch timePeriod {
    case "daily":
      let startOfDay = calendar.startOfDay(for: now)
      let endOfDay = calendar.endOfDay(for: now)
      return DateRange(startOfDay, endOfDay)

    case "weekly":
      if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) {
        return DateRange(weekInterval.start, weekInterval.end)
      }
      return DateRange(now, now)

    case "monthly":
      if let monthInterval = calendar.dateInterval(of: .month, for: now) {
        return DateRange(monthInterval.start, monthInterval.end)
      }
      return DateRange(now, now)

    case "yearly":
      if let yearInterval = calendar.dateInterval(of: .year, for: now) {
        return DateRange(yearInterval.start, yearInterval.end)
      }
      return DateRange(now, now)

    default:
      let startOfDay = calendar.startOfDay(for: now)
      let endOfDay = calendar.endOfDay(for: now)
      return DateRange(startOfDay, endOfDay)
    }
  }
}
