//
//  GoalStreakCalculator.swift
//  Bloom
//
//  Created by Claude on 2026-02-26.
//

import Foundation
import DataContainer
import HealthKit
import CoreHealth
import BloomFoundation

/// Calculates consecutive days a goal was met, ending at yesterday (or today if data available).
final actor GoalStreakCalculator {

  static let shared = GoalStreakCalculator()

  private let modelActor = HabitModelActor.standard()

  private init() { }
}

extension GoalStreakCalculator {

  /// Returns the current streak count for a specific habit (consecutive days goal was met).
  func calculateStreak(for habit: HabitDTO) async -> Int {
    guard habit.timePeriod == .daily else { return 0 }

    let calendar = Calendar.current
    var streakCount = 0
    var currentDate = DateRange.yesterday().start

    // Check up to 365 days back, starting from yesterday
    for _ in 0..<365 {
      let dateRange = DateRange.duringDay(currentDate)
      let quantity = await habit.targetMetric.fetchTotalQuantity(for: dateRange)

      if habit.quantityMeetsGoal(quantity) {
        streakCount += 1
      } else {
        break
      }

      currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
    }

    return streakCount
  }

  /// Returns all active habits with their current streak counts.
  func calculateAllStreaks() async -> [(habit: HabitDTO, streak: Int)] {
    guard let activeHabits = try? await modelActor.fetchActiveHabits() else { return [] }

    var results = [(habit: HabitDTO, streak: Int)]()

    for habit in activeHabits where habit.timePeriod == .daily {
      let streak = await calculateStreak(for: habit)
      if streak > 0 {
        results.append((habit: habit, streak: streak))
      }
    }

    return results
  }
}
