//
//  YearInBloomCalculator.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-12.
//

import Foundation
import HealthKit
import BloomFoundation

public final actor YearInBloomCalculator {
  public static let shared = YearInBloomCalculator()

  @AsyncStreamable public var workoutStats: YearInBloomWorkoutStats?
  @AsyncStreamable public var isCalculating: Bool = false

  private init() { }
}

// MARK: - Public API

public extension YearInBloomCalculator {

  /// Compile stats for the given year
  func compile(for year: Int) async {
    isCalculating = true
    defer { isCalculating = false }

    guard let stats = await calculateStats(for: year) else {
      workoutStats = nil
      return
    }

    workoutStats = stats
  }
}

// MARK: - Core Calculation Logic

private extension YearInBloomCalculator {

  func calculateStats(for year: Int) async -> YearInBloomWorkoutStats? {
    let currentYear = Calendar.current.component(.year, from: .now)
    let yearsFromNow = currentYear - year
    let dateRange = DateRange.specificYear(yearsFromNow)

    // Fetch all workouts for the year
    let workouts = await HealthStoreFetcher.shared.fetchWorkouts(dateRange: dateRange)

    guard workouts.isNotEmpty else { return nil }

    // Fetch zone minutes data for the year
    let heartRateReports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)

    // Group workouts and heart rate reports by month
    let calendar = Calendar.current
    let workoutsByMonth = Dictionary(grouping: workouts) { workout in
      calendar.component(.month, from: workout.startDate)
    }
    let reportsByMonth = Dictionary(grouping: heartRateReports) { report in
      calendar.component(.month, from: report.workout.startDate)
    }

    // Calculate monthly stats for all 12 months
    var monthlyStats = [MonthlyWorkoutStats]()
    var yearZoneMinutes = ZoneMinutesBreakdown.zero

    for month in 1...12 {
      let monthWorkouts = workoutsByMonth[month] ?? []
      let monthReports = reportsByMonth[month] ?? []

      // Calculate zone minutes for this month
      let zoneMinutes: ZoneMinutesBreakdown?
      if monthReports.isNotEmpty {
        let distribution = monthReports.generateOverallDistribution()
        let breakdown = ZoneMinutesBreakdown(
          zone1Minutes: distribution.zone1.doubleValue(for: .minute()),
          zone2Minutes: distribution.zone2.doubleValue(for: .minute()),
          zone3Minutes: distribution.zone3.doubleValue(for: .minute()),
          zone4Minutes: distribution.zone4.doubleValue(for: .minute()),
          zone5Minutes: distribution.zone5.doubleValue(for: .minute())
        )
        zoneMinutes = breakdown
        yearZoneMinutes = yearZoneMinutes + breakdown
      } else {
        zoneMinutes = nil
      }

      let stat = calculateMonthlyStats(
        month: month,
        workouts: monthWorkouts,
        allWorkouts: workouts,
        heartRateReports: monthReports,
        zoneMinutes: zoneMinutes
      )
      monthlyStats.append(stat)
    }

    // Calculate year totals
    let yearTotals = calculateYearTotals(workouts: workouts, totalZoneMinutes: yearZoneMinutes)

    // Calculate top workout types across the year
    let topWorkoutTypes = calculateTopWorkoutTypes(workouts: workouts, heartRateReports: heartRateReports)

    // Calculate longest streak
    let longestStreak = calculateLongestStreak(workouts: workouts)

    // Find best month by duration
    let bestMonth = monthlyStats.max { $0.totalDurationMinutes < $1.totalDurationMinutes }

    // Fetch VO2 max data for the year
    let vo2MaxSamples = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .vo2Max,
      unit: .vo2Max(),
      dateRange: dateRange
    )
    let monthlyVO2Max = calculateMonthlyVO2Max(samples: vo2MaxSamples, year: year)

    return YearInBloomWorkoutStats(
      year: year,
      monthlyStats: monthlyStats,
      yearTotals: yearTotals,
      topWorkoutTypes: topWorkoutTypes,
      longestStreak: longestStreak,
      bestMonth: bestMonth,
      monthlyVO2Max: monthlyVO2Max,
      generatedDate: .now
    )
  }

  func calculateMonthlyStats(
    month: Int,
    workouts: [HKWorkout],
    allWorkouts: [HKWorkout],
    heartRateReports: [WorkoutHeartRateReport],
    zoneMinutes: ZoneMinutesBreakdown?
  ) -> MonthlyWorkoutStats {
    let totalDuration = workouts.reduce(0.0) { $0 + $1.duration / 60 }
    let totalCalories = workouts.reduce(0.0) { total, workout in
      let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .largeCalorie()) ?? 0
      return total + calories
    }

    let typeBreakdown = calculateTopWorkoutTypes(workouts: workouts, heartRateReports: heartRateReports)

    return MonthlyWorkoutStats(
      month: month,
      workoutCount: workouts.count,
      totalDurationMinutes: totalDuration,
      totalCaloriesBurned: totalCalories,
      workoutTypeBreakdown: typeBreakdown,
      zoneMinutes: zoneMinutes
    )
  }

  func calculateYearTotals(workouts: [HKWorkout], totalZoneMinutes: ZoneMinutesBreakdown) -> YearTotals {
    let totalDuration = workouts.reduce(0.0) { $0 + $1.duration / 60 }
    let totalCalories = workouts.reduce(0.0) { total, workout in
      let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .largeCalorie()) ?? 0
      return total + calories
    }
    let uniqueTypes = Set(workouts.map(\.workoutActivityType)).count

    return YearTotals(
      totalWorkouts: workouts.count,
      totalDurationMinutes: totalDuration,
      totalCaloriesBurned: totalCalories,
      uniqueWorkoutTypes: uniqueTypes,
      totalZoneMinutes: totalZoneMinutes
    )
  }

  func calculateTopWorkoutTypes(
    workouts: [HKWorkout],
    heartRateReports: [WorkoutHeartRateReport]
  ) -> [WorkoutTypeStats] {
    let grouped = Dictionary(grouping: workouts) { $0.workoutActivityType }
    let totalDuration = workouts.reduce(0.0) { $0 + $1.duration / 60 }

    // Group heart rate reports by workout type
    let reportsByType = Dictionary(grouping: heartRateReports) { $0.workout.workoutActivityType }

    let stats = grouped.map { (type, typeWorkouts) -> WorkoutTypeStats in
      let typeDuration = typeWorkouts.reduce(0.0) { $0 + $1.duration / 60 }
      let typeCalories = typeWorkouts.reduce(0.0) { total, workout in
        let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .largeCalorie()) ?? 0
        return total + calories
      }

      // Calculate total distance for this workout type
      let typeDistance = typeWorkouts.reduce(0.0) { total, workout in
        total + (workout.totalDistanceWalkingRunningCycling?.doubleValue(for: .meter()) ?? 0)
      }

      // Calculate zone minutes for this workout type
      let typeReports = reportsByType[type] ?? []
      let zoneMinutes: ZoneMinutesBreakdown?
      if typeReports.isNotEmpty {
        let distribution = typeReports.generateOverallDistribution()
        zoneMinutes = ZoneMinutesBreakdown(
          zone1Minutes: distribution.zone1.doubleValue(for: .minute()),
          zone2Minutes: distribution.zone2.doubleValue(for: .minute()),
          zone3Minutes: distribution.zone3.doubleValue(for: .minute()),
          zone4Minutes: distribution.zone4.doubleValue(for: .minute()),
          zone5Minutes: distribution.zone5.doubleValue(for: .minute())
        )
      } else {
        zoneMinutes = nil
      }

      return WorkoutTypeStats(
        activityTypeRawValue: type.rawValue,
        activityName: type.name,
        count: typeWorkouts.count,
        totalDurationMinutes: typeDuration,
        totalCaloriesBurned: typeCalories,
        percentage: totalDuration > 0 ? (typeDuration / totalDuration) * 100 : 0,
        zoneMinutes: zoneMinutes,
        totalDistanceMeters: typeDistance > 0 ? typeDistance : nil
      )
    }

    return Array(stats
      .filter { $0.scaledZoneMinutes > 0 }
      .sorted { $0.scaledZoneMinutes > $1.scaledZoneMinutes }
    )
  }

  func calculateLongestStreak(workouts: [HKWorkout]) -> StreakInfo {
    let calendar = Calendar.current

    // Get unique workout days, sorted
    let sortedDates = Set(workouts.map { calendar.startOfDay(for: $0.startDate) }).sorted()

    guard sortedDates.isNotEmpty else {
      return StreakInfo(longestStreakDays: 0, streakStartDate: nil, streakEndDate: nil)
    }

    var longestStreak = 1
    var currentStreak = 1
    var longestStart = sortedDates[0]
    var longestEnd = sortedDates[0]
    var currentStart = sortedDates[0]

    for i in 1..<sortedDates.count {
      let previousDate = sortedDates[i - 1]
      let currentDate = sortedDates[i]

      // Check if dates are consecutive
      if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
         calendar.isDate(currentDate, inSameDayAs: nextDay) {
        currentStreak += 1
        if currentStreak > longestStreak {
          longestStreak = currentStreak
          longestStart = currentStart
          longestEnd = currentDate
        }
      } else {
        currentStreak = 1
        currentStart = currentDate
      }
    }

    return StreakInfo(
      longestStreakDays: longestStreak,
      streakStartDate: longestStart,
      streakEndDate: longestEnd
    )
  }

  func calculateMonthlyVO2Max(samples: [DateQuantitySample], year: Int) -> [MonthlyVO2MaxData] {
    let calendar = Calendar.current
    let samplesByMonth = Dictionary(grouping: samples) { sample in
      calendar.component(.month, from: sample.date)
    }

    return (1...12).map { (month: Int) -> MonthlyVO2MaxData in
      let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!
      let monthSamples = samplesByMonth[month] ?? []
      let average: Double?
      if monthSamples.isEmpty {
        average = nil
      } else {
        let sum = monthSamples.map { $0.quantity.doubleValue(for: .vo2Max()) }.reduce(0.0, +)
        average = sum / Double(monthSamples.count)
      }
      return MonthlyVO2MaxData(date: date, averageVO2Max: average)
    }
  }
}

