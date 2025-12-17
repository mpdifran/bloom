//
//  YearInBloomViewModel.swift
//  Bloom
//
//  Created by Claude on 2025-12-12.
//

import Foundation
import SwiftUI
import CoreHealth

@MainActor @Observable
final class YearInBloomViewModel {
  var stats: YearInBloomWorkoutStats?
  var sleepStats: YearInBloomSleepStats?
  var menstrualStats: YearInBloomMenstrualStats?
  var isLoading = false
  var error: Error?

  let year: Int

  init(year: Int) {
    self.year = year
  }

  func loadStats() async {
    isLoading = true
    error = nil

    await YearInBloomCalculator.shared.compile(for: year)
    await YearInBloomCalculator.shared.compileSleep(for: year)
    await YearInBloomCalculator.shared.compileMenstrual(for: year)
    stats = await YearInBloomCalculator.shared.workoutStats
    sleepStats = await YearInBloomCalculator.shared.sleepStats
    menstrualStats = await YearInBloomCalculator.shared.menstrualStats

    isLoading = false
  }

  func forceRefresh() async {
    isLoading = true
    error = nil

    await YearInBloomCalculator.shared.compile(for: year)
    await YearInBloomCalculator.shared.compileSleep(for: year)
    await YearInBloomCalculator.shared.compileMenstrual(for: year)
    stats = await YearInBloomCalculator.shared.workoutStats
    sleepStats = await YearInBloomCalculator.shared.sleepStats
    menstrualStats = await YearInBloomCalculator.shared.menstrualStats

    isLoading = false
  }
}

// MARK: - Formatted Values

extension YearInBloomViewModel {

  var formattedYear: String {
    "\(year)"
  }

  var formattedTotalWorkouts: String {
    guard let stats else { return "0" }
    return stats.yearTotals.totalWorkouts.formatted()
  }

  var formattedTotalDuration: String {
    guard let stats else { return "0 hours" }
    let hours = stats.yearTotals.totalDurationHours
    if hours >= 100 {
      return "\(Int(hours)) hours"
    } else {
      return String(format: "%.1f hours", hours)
    }
  }

  var formattedTotalCalories: String {
    guard let stats else { return "0" }
    return stats.yearTotals.totalCaloriesBurned.formatted(.number.precision(.fractionLength(0)))
  }

  var calorieComparisonText: String {
    guard let stats else { return "" }
    return CalorieComparison.bestComparisonText(for: stats.yearTotals.totalCaloriesBurned)
  }

  var topWorkoutTypeName: String {
    stats?.topWorkoutTypes.first?.activityName ?? "Workouts"
  }

  var topWorkoutTypePercentage: String {
    guard let percentage = stats?.topWorkoutTypes.first?.percentage else { return "0%" }
    return String(format: "%.0f%%", percentage)
  }

  var longestStreakDays: String {
    guard let streak = stats?.longestStreak.longestStreakDays else { return "0" }
    return "\(streak)"
  }

  var bestMonthName: String {
    stats?.bestMonth?.monthName ?? ""
  }

  var bestMonthWorkouts: String {
    guard let count = stats?.bestMonth?.workoutCount else { return "0" }
    return "\(count)"
  }
}
