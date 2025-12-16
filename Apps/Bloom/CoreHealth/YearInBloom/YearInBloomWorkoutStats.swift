//
//  YearInBloomWorkoutStats.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-12.
//

import Foundation
import HealthKit

// MARK: - Main Stats Model

public struct YearInBloomWorkoutStats: Sendable, Codable, Hashable {
  public let year: Int
  public let monthlyStats: [MonthlyWorkoutStats]
  public let yearTotals: YearTotals
  public let topWorkoutTypes: [WorkoutTypeStats]
  public let longestStreak: StreakInfo
  public let bestMonth: MonthlyWorkoutStats?
  public let generatedDate: Date

  public init(
    year: Int,
    monthlyStats: [MonthlyWorkoutStats],
    yearTotals: YearTotals,
    topWorkoutTypes: [WorkoutTypeStats],
    longestStreak: StreakInfo,
    bestMonth: MonthlyWorkoutStats?,
    generatedDate: Date
  ) {
    self.year = year
    self.monthlyStats = monthlyStats
    self.yearTotals = yearTotals
    self.topWorkoutTypes = topWorkoutTypes
    self.longestStreak = longestStreak
    self.bestMonth = bestMonth
    self.generatedDate = generatedDate
  }
}

// MARK: - Monthly Stats

public struct MonthlyWorkoutStats: Sendable, Codable, Hashable, Identifiable {
  public var id: Int { month }

  public let month: Int // 1-12
  public let workoutCount: Int
  public let totalDurationMinutes: Double
  public let totalCaloriesBurned: Double
  public let workoutTypeBreakdown: [WorkoutTypeStats]
  public let zoneMinutes: ZoneMinutesBreakdown?

  public init(
    month: Int,
    workoutCount: Int,
    totalDurationMinutes: Double,
    totalCaloriesBurned: Double,
    workoutTypeBreakdown: [WorkoutTypeStats],
    zoneMinutes: ZoneMinutesBreakdown? = nil
  ) {
    self.month = month
    self.workoutCount = workoutCount
    self.totalDurationMinutes = totalDurationMinutes
    self.totalCaloriesBurned = totalCaloriesBurned
    self.workoutTypeBreakdown = workoutTypeBreakdown
    self.zoneMinutes = zoneMinutes
  }

  public var monthName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM"
    let components = DateComponents(month: month)
    guard let date = Calendar.current.date(from: components) else { return "" }
    return formatter.string(from: date)
  }

  public var shortMonthName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    let components = DateComponents(month: month)
    guard let date = Calendar.current.date(from: components) else { return "" }
    return formatter.string(from: date)
  }
}

// MARK: - Year Totals

public struct YearTotals: Sendable, Codable, Hashable {
  public let totalWorkouts: Int
  public let totalDurationMinutes: Double
  public let totalCaloriesBurned: Double
  public let uniqueWorkoutTypes: Int
  public let totalZoneMinutes: ZoneMinutesBreakdown?

  public init(
    totalWorkouts: Int,
    totalDurationMinutes: Double,
    totalCaloriesBurned: Double,
    uniqueWorkoutTypes: Int,
    totalZoneMinutes: ZoneMinutesBreakdown? = nil
  ) {
    self.totalWorkouts = totalWorkouts
    self.totalDurationMinutes = totalDurationMinutes
    self.totalCaloriesBurned = totalCaloriesBurned
    self.uniqueWorkoutTypes = uniqueWorkoutTypes
    self.totalZoneMinutes = totalZoneMinutes
  }

  public var totalDurationHours: Double {
    totalDurationMinutes / 60
  }
}

// MARK: - Workout Type Stats

public struct WorkoutTypeStats: Sendable, Codable, Hashable, Identifiable {
  public var id: UInt { activityTypeRawValue }

  public let activityTypeRawValue: UInt
  public let activityName: String
  public let count: Int
  public let totalDurationMinutes: Double
  public let totalCaloriesBurned: Double
  public let percentage: Double // of total duration
  public let zoneMinutes: ZoneMinutesBreakdown?
  public let totalDistanceMeters: Double?

  public init(
    activityTypeRawValue: UInt,
    activityName: String,
    count: Int,
    totalDurationMinutes: Double,
    totalCaloriesBurned: Double,
    percentage: Double,
    zoneMinutes: ZoneMinutesBreakdown? = nil,
    totalDistanceMeters: Double? = nil
  ) {
    self.activityTypeRawValue = activityTypeRawValue
    self.activityName = activityName
    self.count = count
    self.totalDurationMinutes = totalDurationMinutes
    self.totalCaloriesBurned = totalCaloriesBurned
    self.percentage = percentage
    self.zoneMinutes = zoneMinutes
    self.totalDistanceMeters = totalDistanceMeters
  }

  public var activityType: HKWorkoutActivityType {
    HKWorkoutActivityType(rawValue: activityTypeRawValue) ?? .other
  }

  public var totalDurationHours: Double {
    totalDurationMinutes / 60
  }

  public var scaledZoneMinutes: Double {
    zoneMinutes?.scaledZoneMinutes ?? 0
  }
}

// MARK: - Streak Info

public struct StreakInfo: Sendable, Codable, Hashable {
  public let longestStreakDays: Int
  public let streakStartDate: Date?
  public let streakEndDate: Date?

  public init(
    longestStreakDays: Int,
    streakStartDate: Date?,
    streakEndDate: Date?
  ) {
    self.longestStreakDays = longestStreakDays
    self.streakStartDate = streakStartDate
    self.streakEndDate = streakEndDate
  }
}

// MARK: - Zone Minutes

public struct ZoneMinutesBreakdown: Sendable, Codable, Hashable {
  public let zone1Minutes: Double
  public let zone2Minutes: Double
  public let zone3Minutes: Double
  public let zone4Minutes: Double
  public let zone5Minutes: Double

  public init(
    zone1Minutes: Double,
    zone2Minutes: Double,
    zone3Minutes: Double,
    zone4Minutes: Double,
    zone5Minutes: Double
  ) {
    self.zone1Minutes = zone1Minutes
    self.zone2Minutes = zone2Minutes
    self.zone3Minutes = zone3Minutes
    self.zone4Minutes = zone4Minutes
    self.zone5Minutes = zone5Minutes
  }

  /// Total zone minutes with multipliers applied:
  /// - Zones 1-2: ×1
  /// - Zones 3-4: ×2
  /// - Zone 5: ×3
  public var scaledZoneMinutes: Double {
    zone1Minutes + zone2Minutes +
    (zone3Minutes * 2) + (zone4Minutes * 2) +
    (zone5Minutes * 3)
  }

  /// Convenience initializer with all zeros
  public static var zero: ZoneMinutesBreakdown {
    ZoneMinutesBreakdown(
      zone1Minutes: 0,
      zone2Minutes: 0,
      zone3Minutes: 0,
      zone4Minutes: 0,
      zone5Minutes: 0
    )
  }

  /// Add two breakdowns together
  public static func + (lhs: ZoneMinutesBreakdown, rhs: ZoneMinutesBreakdown) -> ZoneMinutesBreakdown {
    ZoneMinutesBreakdown(
      zone1Minutes: lhs.zone1Minutes + rhs.zone1Minutes,
      zone2Minutes: lhs.zone2Minutes + rhs.zone2Minutes,
      zone3Minutes: lhs.zone3Minutes + rhs.zone3Minutes,
      zone4Minutes: lhs.zone4Minutes + rhs.zone4Minutes,
      zone5Minutes: lhs.zone5Minutes + rhs.zone5Minutes
    )
  }
}

// MARK: - Chart Data Helpers

public extension YearInBloomWorkoutStats {

  /// Monthly workout counts for charting (DateValueSample format)
  func monthlyWorkoutCounts() -> [DateValueSample] {
    monthlyStats.compactMap { stat in
      guard let date = Calendar.current.date(from: DateComponents(year: year, month: stat.month, day: 15)) else {
        return nil
      }
      return DateValueSample(date: date, value: Double(stat.workoutCount))
    }
  }

  /// Monthly duration in hours for charting
  func monthlyDurationHours() -> [DateValueSample] {
    monthlyStats.compactMap { stat in
      guard let date = Calendar.current.date(from: DateComponents(year: year, month: stat.month, day: 15)) else {
        return nil
      }
      return DateValueSample(date: date, value: stat.totalDurationMinutes / 60)
    }
  }

  /// Monthly calories for charting
  func monthlyCalories() -> [DateValueSample] {
    monthlyStats.compactMap { stat in
      guard let date = Calendar.current.date(from: DateComponents(year: year, month: stat.month, day: 15)) else {
        return nil
      }
      return DateValueSample(date: date, value: stat.totalCaloriesBurned)
    }
  }

  /// Peak month by workout count
  var peakMonthByCount: MonthlyWorkoutStats? {
    monthlyStats.max { $0.workoutCount < $1.workoutCount }
  }

  /// Peak month by duration
  var peakMonthByDuration: MonthlyWorkoutStats? {
    monthlyStats.max { $0.totalDurationMinutes < $1.totalDurationMinutes }
  }

  /// Peak month by calories
  var peakMonthByCalories: MonthlyWorkoutStats? {
    monthlyStats.max { $0.totalCaloriesBurned < $1.totalCaloriesBurned }
  }

  /// Workout types that have distance data, sorted by distance (highest first)
  var workoutTypesByDistance: [WorkoutTypeStats] {
    topWorkoutTypes
      .filter { $0.totalDistanceMeters != nil && $0.totalDistanceMeters! > 0 }
      .sorted { ($0.totalDistanceMeters ?? 0) > ($1.totalDistanceMeters ?? 0) }
  }

  /// Total distance across all workout types in meters
  var totalDistanceMeters: Double {
    topWorkoutTypes.compactMap(\.totalDistanceMeters).reduce(0, +)
  }

  /// Monthly zone minutes for charting (with scaled values)
  func monthlyScaledZoneMinutes() -> [MonthlyZoneMinutesData] {
    monthlyStats.compactMap { stat in
      guard let date = Calendar.current.date(from: DateComponents(year: year, month: stat.month, day: 15)) else {
        return nil
      }
      let zones = stat.zoneMinutes ?? .zero
      return MonthlyZoneMinutesData(
        date: date,
        zone1: zones.zone1Minutes,
        zone2: zones.zone2Minutes,
        zone3: zones.zone3Minutes * 2,  // Apply ×2 multiplier
        zone4: zones.zone4Minutes * 2,  // Apply ×2 multiplier
        zone5: zones.zone5Minutes * 3   // Apply ×3 multiplier
      )
    }
  }

  /// Monthly zone minutes filtered by a specific workout type
  func monthlyScaledZoneMinutes(for workoutType: WorkoutTypeStats) -> [MonthlyZoneMinutesData] {
    monthlyStats.compactMap { stat in
      guard let date = Calendar.current.date(from: DateComponents(year: year, month: stat.month, day: 15)) else {
        return nil
      }
      let typeStats = stat.workoutTypeBreakdown.first(where: { $0.activityTypeRawValue == workoutType.activityTypeRawValue })
      let zones = typeStats?.zoneMinutes ?? .zero
      return MonthlyZoneMinutesData(
        date: date,
        zone1: zones.zone1Minutes,
        zone2: zones.zone2Minutes,
        zone3: zones.zone3Minutes * 2,
        zone4: zones.zone4Minutes * 2,
        zone5: zones.zone5Minutes * 3
      )
    }
  }
}

// MARK: - Zone Minutes Chart Data

public struct MonthlyZoneMinutesData: Identifiable {
  public var id: Date { date }  // Use date as stable ID to prevent infinite re-renders
  public let date: Date
  public let zone1: Double
  public let zone2: Double
  public let zone3: Double
  public let zone4: Double
  public let zone5: Double

  public init(
    date: Date,
    zone1: Double,
    zone2: Double,
    zone3: Double,
    zone4: Double,
    zone5: Double
  ) {
    self.date = date
    self.zone1 = zone1
    self.zone2 = zone2
    self.zone3 = zone3
    self.zone4 = zone4
    self.zone5 = zone5
  }

  public var total: Double {
    zone1 + zone2 + zone3 + zone4 + zone5
  }
}

// MARK: - Workout Type Composition for Stacked Charts

public extension YearInBloomWorkoutStats {

  /// Get workout type breakdown by month for stacked area chart
  /// Returns a dictionary mapping workout type to array of monthly values
  func workoutTypeCompositionByMonth(topN: Int = 5) -> [String: [DateValueSample]] {
    var result = [String: [DateValueSample]]()

    // Get the top N workout types by total duration
    let topTypes = Array(topWorkoutTypes.prefix(topN))
    let topTypeNames = Set(topTypes.map(\.activityName))

    for stat in monthlyStats {
      guard let date = Calendar.current.date(from: DateComponents(year: year, month: stat.month, day: 15)) else {
        continue
      }

      // Add samples for each top workout type
      for typeStats in stat.workoutTypeBreakdown {
        let name = topTypeNames.contains(typeStats.activityName) ? typeStats.activityName : "Other"
        let sample = DateValueSample(date: date, value: typeStats.totalDurationMinutes / 60)

        if result[name] != nil {
          result[name]?.append(sample)
        } else {
          result[name] = [sample]
        }
      }

      // Ensure all top types have an entry for this month (even if 0)
      for typeName in topTypeNames {
        if result[typeName]?.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) != true {
          if result[typeName] != nil {
            result[typeName]?.append(DateValueSample(date: date, value: 0))
          } else {
            result[typeName] = [DateValueSample(date: date, value: 0)]
          }
        }
      }
    }

    // Sort each array by date
    for key in result.keys {
      result[key]?.sort { $0.date < $1.date }
    }

    return result
  }
}
