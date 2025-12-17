//
//  YearInBloomSleepStats+Preview.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-16.
//

import Foundation

public extension YearInBloomSleepStats {
  static var preview: YearInBloomSleepStats {
    // Bedtime: ~11 PM (660 minutes from noon)
    // Wake time: ~7-8 AM (1140-1200 minutes from noon)
    let monthlySleepStats = [
      MonthlySleepStats(
        month: 1,
        sleepSessionCount: 28,
        averageCoreSleepPercent: 0.52,
        averageDeepSleepPercent: 0.12,
        averageRemSleepPercent: 0.22,
        averageAwakeSleepPercent: 0.14,
        averageCoreSleepMinutes: 218,
        averageDeepSleepMinutes: 50,
        averageRemSleepMinutes: 92,
        averageAwakeSleepMinutes: 59,
        averageSleepDurationMinutes: 420,
        averageSleepScore: 72,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1155 // 7:15 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 2,
        sleepSessionCount: 26,
        averageCoreSleepPercent: 0.50,
        averageDeepSleepPercent: 0.14,
        averageRemSleepPercent: 0.24,
        averageAwakeSleepPercent: 0.12,
        averageCoreSleepMinutes: 218,
        averageDeepSleepMinutes: 61,
        averageRemSleepMinutes: 104,
        averageAwakeSleepMinutes: 52,
        averageSleepDurationMinutes: 435,
        averageSleepScore: 76,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1155 // 7:15 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 3,
        sleepSessionCount: 29,
        averageCoreSleepPercent: 0.48,
        averageDeepSleepPercent: 0.15,
        averageRemSleepPercent: 0.25,
        averageAwakeSleepPercent: 0.12,
        averageCoreSleepMinutes: 214,
        averageDeepSleepMinutes: 67,
        averageRemSleepMinutes: 111,
        averageAwakeSleepMinutes: 53,
        averageSleepDurationMinutes: 445,
        averageSleepScore: 78,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1140 // 7:00 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 4,
        sleepSessionCount: 28,
        averageCoreSleepPercent: 0.46,
        averageDeepSleepPercent: 0.16,
        averageRemSleepPercent: 0.26,
        averageAwakeSleepPercent: 0.12,
        averageCoreSleepMinutes: 207,
        averageDeepSleepMinutes: 72,
        averageRemSleepMinutes: 117,
        averageAwakeSleepMinutes: 54,
        averageSleepDurationMinutes: 450,
        averageSleepScore: 80,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1170 // 7:30 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 5,
        sleepSessionCount: 30,
        averageCoreSleepPercent: 0.45,
        averageDeepSleepPercent: 0.17,
        averageRemSleepPercent: 0.27,
        averageAwakeSleepPercent: 0.11,
        averageCoreSleepMinutes: 205,
        averageDeepSleepMinutes: 77,
        averageRemSleepMinutes: 123,
        averageAwakeSleepMinutes: 50,
        averageSleepDurationMinutes: 455,
        averageSleepScore: 82,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1185 // 7:45 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 6,
        sleepSessionCount: 29,
        averageCoreSleepPercent: 0.44,
        averageDeepSleepPercent: 0.18,
        averageRemSleepPercent: 0.28,
        averageAwakeSleepPercent: 0.10,
        averageCoreSleepMinutes: 202,
        averageDeepSleepMinutes: 83,
        averageRemSleepMinutes: 129,
        averageAwakeSleepMinutes: 46,
        averageSleepDurationMinutes: 460,
        averageSleepScore: 85,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1200 // 8:00 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 7,
        sleepSessionCount: 30,
        averageCoreSleepPercent: 0.46,
        averageDeepSleepPercent: 0.17,
        averageRemSleepPercent: 0.27,
        averageAwakeSleepPercent: 0.10,
        averageCoreSleepMinutes: 209,
        averageDeepSleepMinutes: 77,
        averageRemSleepMinutes: 123,
        averageAwakeSleepMinutes: 46,
        averageSleepDurationMinutes: 455,
        averageSleepScore: 83,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1185 // 7:45 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 8,
        sleepSessionCount: 30,
        averageCoreSleepPercent: 0.48,
        averageDeepSleepPercent: 0.16,
        averageRemSleepPercent: 0.26,
        averageAwakeSleepPercent: 0.10,
        averageCoreSleepMinutes: 216,
        averageDeepSleepMinutes: 72,
        averageRemSleepMinutes: 117,
        averageAwakeSleepMinutes: 45,
        averageSleepDurationMinutes: 450,
        averageSleepScore: 81,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1170 // 7:30 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 9,
        sleepSessionCount: 28,
        averageCoreSleepPercent: 0.50,
        averageDeepSleepPercent: 0.15,
        averageRemSleepPercent: 0.24,
        averageAwakeSleepPercent: 0.11,
        averageCoreSleepMinutes: 223,
        averageDeepSleepMinutes: 67,
        averageRemSleepMinutes: 107,
        averageAwakeSleepMinutes: 49,
        averageSleepDurationMinutes: 445,
        averageSleepScore: 79,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1155 // 7:15 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 10,
        sleepSessionCount: 29,
        averageCoreSleepPercent: 0.51,
        averageDeepSleepPercent: 0.14,
        averageRemSleepPercent: 0.23,
        averageAwakeSleepPercent: 0.12,
        averageCoreSleepMinutes: 224,
        averageDeepSleepMinutes: 62,
        averageRemSleepMinutes: 101,
        averageAwakeSleepMinutes: 53,
        averageSleepDurationMinutes: 440,
        averageSleepScore: 77,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1155 // 7:15 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 11,
        sleepSessionCount: 27,
        averageCoreSleepPercent: 0.52,
        averageDeepSleepPercent: 0.13,
        averageRemSleepPercent: 0.22,
        averageAwakeSleepPercent: 0.13,
        averageCoreSleepMinutes: 224,
        averageDeepSleepMinutes: 56,
        averageRemSleepMinutes: 95,
        averageAwakeSleepMinutes: 56,
        averageSleepDurationMinutes: 430,
        averageSleepScore: 74,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1140 // 7:00 AM (minutes from noon)
      ),
      MonthlySleepStats(
        month: 12,
        sleepSessionCount: 28,
        averageCoreSleepPercent: 0.53,
        averageDeepSleepPercent: 0.12,
        averageRemSleepPercent: 0.21,
        averageAwakeSleepPercent: 0.14,
        averageCoreSleepMinutes: 225,
        averageDeepSleepMinutes: 51,
        averageRemSleepMinutes: 89,
        averageAwakeSleepMinutes: 60,
        averageSleepDurationMinutes: 425,
        averageSleepScore: 72,
        averageBedtimeMinutes: 660, // 11:00 PM (minutes from noon)
        averageWakeTimeMinutes: 1155 // 7:15 AM (minutes from noon)
      )
    ]

    return YearInBloomSleepStats(
      year: 2024,
      monthlySleepStats: monthlySleepStats,
      yearTotals: SleepYearTotals(
        totalSleepSessions: 342,
        averageCoreSleepPercent: 0.49,
        averageDeepSleepPercent: 0.15,
        averageRemSleepPercent: 0.25,
        averageAwakeSleepPercent: 0.11,
        averageSleepDurationMinutes: 443,
        averageSleepScore: 78
      ),
      lowestSleepScore: SleepScoreExtreme(score: 42, month: 1),
      highestSleepScore: SleepScoreExtreme(score: 96, month: 6),
      generatedDate: .now
    )
  }
}
