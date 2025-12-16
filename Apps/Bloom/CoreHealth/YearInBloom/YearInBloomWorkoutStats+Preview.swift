//
//  YearInBloomWorkoutStats+Preview.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-15.
//

import Foundation

// MARK: - Preview Data

public extension YearInBloomWorkoutStats {
  static var preview: YearInBloomWorkoutStats {
    // Use fixed values instead of random to prevent infinite re-renders in SwiftUI previews
    let monthlyStats = [
      MonthlyWorkoutStats(month: 1, workoutCount: 12, totalDurationMinutes: 720, totalCaloriesBurned: 4800, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 30, zone2Minutes: 60, zone3Minutes: 75, zone4Minutes: 45, zone5Minutes: 15)),
      MonthlyWorkoutStats(month: 2, workoutCount: 15, totalDurationMinutes: 900, totalCaloriesBurned: 6000, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 35, zone2Minutes: 70, zone3Minutes: 90, zone4Minutes: 55, zone5Minutes: 20)),
      MonthlyWorkoutStats(month: 3, workoutCount: 18, totalDurationMinutes: 1080, totalCaloriesBurned: 7200, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 40, zone2Minutes: 80, zone3Minutes: 100, zone4Minutes: 60, zone5Minutes: 22)),
      MonthlyWorkoutStats(month: 4, workoutCount: 20, totalDurationMinutes: 1200, totalCaloriesBurned: 8000, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 45, zone2Minutes: 85, zone3Minutes: 105, zone4Minutes: 65, zone5Minutes: 25)),
      MonthlyWorkoutStats(month: 5, workoutCount: 22, totalDurationMinutes: 1320, totalCaloriesBurned: 8800, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 50, zone2Minutes: 90, zone3Minutes: 110, zone4Minutes: 70, zone5Minutes: 28)),
      MonthlyWorkoutStats(month: 6, workoutCount: 25, totalDurationMinutes: 1500, totalCaloriesBurned: 10000, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 55, zone2Minutes: 95, zone3Minutes: 115, zone4Minutes: 75, zone5Minutes: 30)),
      MonthlyWorkoutStats(month: 7, workoutCount: 23, totalDurationMinutes: 1380, totalCaloriesBurned: 9200, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 52, zone2Minutes: 92, zone3Minutes: 112, zone4Minutes: 72, zone5Minutes: 27)),
      MonthlyWorkoutStats(month: 8, workoutCount: 21, totalDurationMinutes: 1260, totalCaloriesBurned: 8400, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 48, zone2Minutes: 88, zone3Minutes: 108, zone4Minutes: 68, zone5Minutes: 25)),
      MonthlyWorkoutStats(month: 9, workoutCount: 19, totalDurationMinutes: 1140, totalCaloriesBurned: 7600, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 44, zone2Minutes: 84, zone3Minutes: 104, zone4Minutes: 64, zone5Minutes: 23)),
      MonthlyWorkoutStats(month: 10, workoutCount: 16, totalDurationMinutes: 960, totalCaloriesBurned: 6400, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 38, zone2Minutes: 75, zone3Minutes: 95, zone4Minutes: 58, zone5Minutes: 21)),
      MonthlyWorkoutStats(month: 11, workoutCount: 14, totalDurationMinutes: 840, totalCaloriesBurned: 5600, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 33, zone2Minutes: 65, zone3Minutes: 82, zone4Minutes: 50, zone5Minutes: 18)),
      MonthlyWorkoutStats(month: 12, workoutCount: 10, totalDurationMinutes: 600, totalCaloriesBurned: 4000, workoutTypeBreakdown: [], zoneMinutes: ZoneMinutesBreakdown(zone1Minutes: 25, zone2Minutes: 50, zone3Minutes: 65, zone4Minutes: 40, zone5Minutes: 12))
    ]

    let totalZones = monthlyStats.compactMap(\.zoneMinutes).reduce(ZoneMinutesBreakdown.zero, +)

    // Monthly VO2 max data with variation (values in ml/kg/min)
    let monthlyVO2Max = [
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!, averageVO2Max: 38.5),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 15))!, averageVO2Max: 39.2),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 15))!, averageVO2Max: 40.1),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 15))!, averageVO2Max: 41.5),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 5, day: 15))!, averageVO2Max: 42.8),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15))!, averageVO2Max: 44.2),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 15))!, averageVO2Max: 45.0),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 15))!, averageVO2Max: 44.5),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 15))!, averageVO2Max: 43.8),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 10, day: 15))!, averageVO2Max: 42.5),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 15))!, averageVO2Max: 41.2),
      MonthlyVO2MaxData(date: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 15))!, averageVO2Max: 40.0)
    ]

    return YearInBloomWorkoutStats(
      year: 2024,
      monthlyStats: monthlyStats,
      yearTotals: YearTotals(
        totalWorkouts: 156,
        totalDurationMinutes: 9500,
        totalCaloriesBurned: 85000,
        uniqueWorkoutTypes: 8,
        totalZoneMinutes: totalZones
      ),
      topWorkoutTypes: [
        WorkoutTypeStats(
          activityTypeRawValue: 52, // Walking
          activityName: "Walking",
          count: 52,
          totalDurationMinutes: 3120,
          totalCaloriesBurned: 31200,
          percentage: 33,
          zoneMinutes: ZoneMinutesBreakdown(
            zone1Minutes: 200,
            zone2Minutes: 400,
            zone3Minutes: 300,
            zone4Minutes: 150,
            zone5Minutes: 50
          ),
          totalDistanceMeters: 312000 // 312 km
        ),
        WorkoutTypeStats(
          activityTypeRawValue: 37, // Running
          activityName: "Running",
          count: 35,
          totalDurationMinutes: 2625,
          totalCaloriesBurned: 21000,
          percentage: 28,
          zoneMinutes: ZoneMinutesBreakdown(
            zone1Minutes: 150,
            zone2Minutes: 350,
            zone3Minutes: 250,
            zone4Minutes: 100,
            zone5Minutes: 30
          ),
          totalDistanceMeters: 245000 // 245 km
        ),
        WorkoutTypeStats(
          activityTypeRawValue: 13, // Cycling
          activityName: "Cycling",
          count: 20,
          totalDurationMinutes: 1800,
          totalCaloriesBurned: 12000,
          percentage: 19,
          zoneMinutes: ZoneMinutesBreakdown(
            zone1Minutes: 100,
            zone2Minutes: 200,
            zone3Minutes: 150,
            zone4Minutes: 80,
            zone5Minutes: 20
          ),
          totalDistanceMeters: 520000 // 520 km
        ),
        WorkoutTypeStats(
          activityTypeRawValue: 24, // Hiking
          activityName: "Hiking",
          count: 15,
          totalDurationMinutes: 1200,
          totalCaloriesBurned: 9000,
          percentage: 12,
          zoneMinutes: ZoneMinutesBreakdown(
            zone1Minutes: 80,
            zone2Minutes: 160,
            zone3Minutes: 120,
            zone4Minutes: 60,
            zone5Minutes: 15
          ),
          totalDistanceMeters: 85000 // 85 km
        ),
        WorkoutTypeStats(
          activityTypeRawValue: 50, // Yoga
          activityName: "Yoga",
          count: 40,
          totalDurationMinutes: 2400,
          totalCaloriesBurned: 16000,
          percentage: 8,
          zoneMinutes: ZoneMinutesBreakdown(
            zone1Minutes: 100,
            zone2Minutes: 200,
            zone3Minutes: 150,
            zone4Minutes: 80,
            zone5Minutes: 20
          )
          // No distance for Yoga
        )
      ],
      longestStreak: StreakInfo(
        longestStreakDays: 14,
        streakStartDate: Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 1)),
        streakEndDate: Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 14))
      ),
      bestMonth: monthlyStats.max { $0.totalDurationMinutes < $1.totalDurationMinutes },
      monthlyVO2Max: monthlyVO2Max,
      generatedDate: .now
    )
  }
}
