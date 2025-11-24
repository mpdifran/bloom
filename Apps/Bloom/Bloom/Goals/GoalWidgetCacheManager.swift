//
//  GoalWidgetCacheManager.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-30.
//

import Foundation
import SwiftData
import SwiftUI
import DataContainer
import CoreHealth
import BloomFoundation

/// Manager responsible for updating goal widget cache when goals change
@MainActor
public final class GoalWidgetCacheManager {
  public static let shared = GoalWidgetCacheManager()

  private init() {}

  /// Update the widget cache with all active goals
  /// Call this whenever goals are created, updated, or deleted
  public func updateCache(modelContext: ModelContext) async {
    do {
      // Fetch all active goals
      let descriptor = FetchDescriptor<Habit>(
        predicate: #Predicate<Habit> { habit in
          habit.endDate == nil
        },
        sortBy: [SortDescriptor(\Habit.startDate)]
      )

      let goals = try modelContext.fetch(descriptor)

      // Convert to widget data format sequentially
      var goalWidgetData: [GoalWidgetData] = []
      for goal in goals {
        if let data = await convertToWidgetData(goal: goal, modelContext: modelContext) {
          goalWidgetData.append(data)
        }
      }

      // Cache all goals
      GoalWidgetCache.cacheGoals(goalWidgetData)

    } catch {
      print("Failed to update goal widget cache: \(error)")
    }
  }

  /// Convert a Habit model to GoalWidgetData
  private func convertToWidgetData(goal: Habit, modelContext: ModelContext) async -> GoalWidgetData? {
    // Use targetMetric as ID since only one active goal per type
    let goalId = goal.targetMetric.rawValue

    // Calculate current value based on time period
    let currentValue = await calculateCurrentValue(for: goal)

    // Calculate grid data based on time period
    let gridData: GoalWidgetData.GridData
    switch goal.timePeriod {
    case .daily:
      gridData = .daily(await calculateDailyGridData(for: goal, modelContext: modelContext))
    case .weekly:
      gridData = .weekly(await calculateWeeklyGridData(for: goal, modelContext: modelContext))
    case .monthly:
      gridData = .monthly(await calculateMonthlyGridData(for: goal, modelContext: modelContext))
    case .yearly:
      gridData = .yearly(await calculateYearlyGridData(for: goal, modelContext: modelContext))
    @unknown default:
      gridData = .daily(GoalWidgetData.DailyGridData(weeks: []))
    }

    return GoalWidgetData(
      id: goalId,
      targetMetricRawValue: goal.targetMetric.rawValue,
      currentValue: currentValue,
      targetValue: goal.value,
      targetUnit: goal.unit.sensibleUnitString,
      timePeriod: goal.timePeriod.rawValue,
      gridData: gridData
    )
  }

  /// Calculate current value for the goal based on its time period
  private func calculateCurrentValue(for goal: Habit) async -> Double {
    let calendar = Calendar.current
    let now = Date()

    // Determine the date range based on time period
    let dateRange: DateRange
    switch goal.timePeriod {
    case .daily:
      let startOfDay = calendar.startOfDay(for: now)
      let endOfDay = calendar.endOfDay(for: now)
      dateRange = DateRange(startOfDay, endOfDay)
    case .weekly:
      guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
        return 0
      }
      dateRange = DateRange(weekInterval.start, weekInterval.end)
    case .monthly:
      guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
        return 0
      }
      dateRange = DateRange(monthInterval.start, monthInterval.end)
    case .yearly:
      guard let yearInterval = calendar.dateInterval(of: .year, for: now) else {
        return 0
      }
      dateRange = DateRange(yearInterval.start, yearInterval.end)
    @unknown default:
      return 0
    }

    // Fetch the total quantity for the period
    let quantity = await goal.targetMetric.fetchTotalQuantity(for: dateRange)

    // Convert to the goal's unit
    let value = quantity.doubleValue(for: goal.unit)
    return value
  }

  /// Calculate daily grid completion data (40 weeks with 7 days each)
  private func calculateDailyGridData(for goal: Habit, modelContext: ModelContext) async -> GoalWidgetData.DailyGridData {
    let calendar = Calendar.current
    let today = Date()

    // Fetch all habits with the same target metric to handle goal changes over time
    let habitHistory: [Habit]
    do {
      habitHistory = try modelContext.fetchHabits(for: goal.targetMetric)
    } catch {
      print("Failed to fetch habit history: \(error)")
      return GoalWidgetData.DailyGridData(weeks: [])
    }

    let oldestHabit = habitHistory.first
    var weeks: [GoalWidgetData.DailyGridData.Week] = []

    for weekOffset in 0..<40 {
      guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start else {
        continue
      }

      var dayCompletions: [Bool] = []
      var todayIndex: Int?

      // Check each day of the week
      for dayOffset in 0..<7 {
        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
          break
        }

        // Stop adding days if we reach the future
        if day > today {
          break
        }

        // Check if this is today
        if calendar.isDate(day, inSameDayAs: today) {
          todayIndex = dayOffset
        }

        // Find which habit was active during this day
        let referenceHabit: Habit?
        if let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: day) }) {
          referenceHabit = habit
        } else if let oldestHabit, day < oldestHabit.startDate {
          // Day is before oldest habit - use oldest habit's goal for comparison
          referenceHabit = oldestHabit
        } else {
          // No habit active during this day (after all habits ended)
          referenceHabit = nil
        }

        // Check if goal was met on this day
        let goalMet: Bool
        if let referenceHabit = referenceHabit {
          // Create date range for the specific day
          let startOfDay = calendar.startOfDay(for: day)
          let endOfDay = calendar.endOfDay(for: day)
          let dateRange = DateRange(startOfDay, endOfDay)

          // Fetch the total quantity for this day from HealthKit
          let quantity = await goal.targetMetric.fetchTotalQuantity(for: dateRange)

          // Check if the quantity meets the goal
          goalMet = referenceHabit.quantityMeetsGoal(quantity)
        } else {
          goalMet = false
        }

        dayCompletions.append(goalMet)
      }

      weeks.insert(
        GoalWidgetData.DailyGridData.Week(
          id: weekOffset,
          isComplete: dayCompletions,
          todayIndex: weekOffset == 0 ? todayIndex : nil
        ),
        at: 0
      )
    }

    // Back-fill with empty weeks if we don't have enough to fill the widget
    if weeks.count < 40 {
      var earliestId = weeks.first?.id ?? 0
      let remainingAdditions = 40 - weeks.count

      for _ in 0..<remainingAdditions {
        earliestId += 1
        let week = GoalWidgetData.DailyGridData.Week(
          id: earliestId,
          isComplete: Array(repeating: false, count: 7),
          todayIndex: nil
        )
        weeks.insert(week, at: 0)
      }
    }

    return GoalWidgetData.DailyGridData(weeks: weeks)
  }

  /// Calculate weekly grid completion data (20 weeks)
  private func calculateWeeklyGridData(for goal: Habit, modelContext: ModelContext) async -> GoalWidgetData.WeeklyGridData {
    let calendar = Calendar.current
    let today = Date()

    // Fetch all habits with the same target metric to handle goal changes over time
    let habitHistory: [Habit]
    do {
      habitHistory = try modelContext.fetchHabits(for: goal.targetMetric)
    } catch {
      print("Failed to fetch habit history: \(error)")
      return GoalWidgetData.WeeklyGridData(weeks: [])
    }

    let oldestHabit = habitHistory.first
    var weeks: [GoalWidgetData.WeeklyGridData.Week] = []

    for weekOffset in 0..<20 {
      guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start,
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.end else {
        continue
      }

      let isCurrentWeek = weekOffset == 0

      // Find which habit was active during this week
      let referenceHabit: Habit?
      if let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: startOfWeek) }) {
        referenceHabit = habit
      } else if let oldestHabit, startOfWeek < oldestHabit.startDate {
        // Week is before oldest habit - use oldest habit's goal for comparison
        referenceHabit = oldestHabit
      } else {
        // No habit active during this week (after all habits ended)
        referenceHabit = nil
      }

      // Fetch total quantity for the week
      let dateRange = DateRange(startOfWeek, endOfWeek)
      let quantity = await goal.targetMetric.fetchTotalQuantity(for: dateRange)

      // Check if quantity meets the goal (false if no habit reference)
      let isComplete = referenceHabit?.quantityMeetsGoal(quantity) ?? false

      // Add month label if this is the first week of a month
      let monthLabel = calendar.component(.weekOfMonth, from: startOfWeek) == 1
        ? startOfWeek.formatted(.dateTime.month(.abbreviated))
        : nil

      weeks.insert(
        GoalWidgetData.WeeklyGridData.Week(
          id: weekOffset,
          isComplete: isComplete,
          isCurrentWeek: isCurrentWeek,
          monthLabel: monthLabel
        ),
        at: 0
      )
    }

    return GoalWidgetData.WeeklyGridData(weeks: weeks)
  }

  /// Calculate monthly grid completion data (12 months)
  private func calculateMonthlyGridData(for goal: Habit, modelContext: ModelContext) async -> GoalWidgetData.MonthlyGridData {
    let calendar = Calendar.current
    let today = Date()

    // Fetch all habits with the same target metric to handle goal changes over time
    let habitHistory: [Habit]
    do {
      habitHistory = try modelContext.fetchHabits(for: goal.targetMetric)
    } catch {
      print("Failed to fetch habit history: \(error)")
      return GoalWidgetData.MonthlyGridData(months: [])
    }

    let oldestHabit = habitHistory.first
    var months: [GoalWidgetData.MonthlyGridData.Month] = []

    for monthOffset in 0..<12 {
      guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: today),
            let startOfMonth = calendar.dateInterval(of: .month, for: monthStart)?.start,
            let endOfMonth = calendar.dateInterval(of: .month, for: monthStart)?.end else {
        continue
      }

      let isCurrentMonth = monthOffset == 0
      let monthLabel = startOfMonth.formatted(.dateTime.month(.abbreviated))

      // Find which habit was active during this month
      let referenceHabit: Habit?
      if let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: startOfMonth) }) {
        referenceHabit = habit
      } else if let oldestHabit, startOfMonth < oldestHabit.startDate {
        // Month is before oldest habit - use oldest habit's goal for comparison
        referenceHabit = oldestHabit
      } else {
        // No habit active during this month (after all habits ended)
        referenceHabit = nil
      }

      // Fetch total quantity for the month
      let dateRange = DateRange(startOfMonth, endOfMonth)
      let quantity = await goal.targetMetric.fetchTotalQuantity(for: dateRange)

      // Check if quantity meets the goal (false if no habit reference)
      let isComplete = referenceHabit?.quantityMeetsGoal(quantity) ?? false

      months.insert(
        GoalWidgetData.MonthlyGridData.Month(
          id: monthOffset,
          isComplete: isComplete,
          isCurrentMonth: isCurrentMonth,
          monthLabel: monthLabel
        ),
        at: 0
      )
    }

    return GoalWidgetData.MonthlyGridData(months: months)
  }

  /// Calculate yearly grid completion data (5 years)
  private func calculateYearlyGridData(for goal: Habit, modelContext: ModelContext) async -> GoalWidgetData.YearlyGridData {
    let calendar = Calendar.current
    let today = Date()

    // Fetch all habits with the same target metric to handle goal changes over time
    let habitHistory: [Habit]
    do {
      habitHistory = try modelContext.fetchHabits(for: goal.targetMetric)
    } catch {
      print("Failed to fetch habit history: \(error)")
      return GoalWidgetData.YearlyGridData(years: [])
    }

    let oldestHabit = habitHistory.first
    var years: [GoalWidgetData.YearlyGridData.Year] = []

    for yearOffset in 0..<5 {
      guard let yearStart = calendar.date(byAdding: .year, value: -yearOffset, to: today),
            let startOfYear = calendar.dateInterval(of: .year, for: yearStart)?.start,
            let endOfYear = calendar.dateInterval(of: .year, for: yearStart)?.end else {
        continue
      }

      let isCurrentYear = yearOffset == 0
      let yearLabel = startOfYear.formatted(.dateTime.year())

      // Find which habit was active during this year
      let referenceHabit: Habit?
      if let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: startOfYear) }) {
        referenceHabit = habit
      } else if let oldestHabit, startOfYear < oldestHabit.startDate {
        // Year is before oldest habit - use oldest habit's goal for comparison
        referenceHabit = oldestHabit
      } else {
        // No habit active during this year (after all habits ended)
        referenceHabit = nil
      }

      // Fetch total quantity for the year
      let dateRange = DateRange(startOfYear, endOfYear)
      let quantity = await goal.targetMetric.fetchTotalQuantity(for: dateRange)

      // Check if quantity meets the goal (false if no habit reference)
      let isComplete = referenceHabit?.quantityMeetsGoal(quantity) ?? false

      years.insert(
        GoalWidgetData.YearlyGridData.Year(
          id: yearOffset,
          isComplete: isComplete,
          isCurrentYear: isCurrentYear,
          yearLabel: yearLabel
        ),
        at: 0
      )
    }

    return GoalWidgetData.YearlyGridData(years: years)
  }
}

