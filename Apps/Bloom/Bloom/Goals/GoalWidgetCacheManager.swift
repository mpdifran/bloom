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

      // Convert to widget data format
      let goalWidgetData = await withTaskGroup(of: GoalWidgetData?.self) { group in
        for goal in goals {
          group.addTask {
            await self.convertToWidgetData(goal: goal, modelContext: modelContext)
          }
        }

        var results: [GoalWidgetData] = []
        for await data in group {
          if let data = data {
            results.append(data)
          }
        }
        return results
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
    }

    // Get color hex string (add # prefix since toHex returns without it)
    let colorHex = goal.targetMetric.color.toHex().map { "#\($0)" } ?? "#FF6B6B"

    return GoalWidgetData(
      id: goalId,
      name: goal.targetMetric.name,
      systemImage: goal.targetMetric.systemImage,
      colorHex: colorHex,
      targetValue: goal.value,
      targetUnit: goal.unit.sensibleUnitString,
      timePeriod: goal.timePeriod.rawValue,
      gridData: gridData
    )
  }

  /// Calculate daily grid completion data (40 weeks with 7 days each)
  private func calculateDailyGridData(for goal: Habit, modelContext: ModelContext) async -> GoalWidgetData.DailyGridData {
    let calendar = Calendar.current
    let today = Date()

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

        // Check if goal was met on this day
        let goalMet = await checkGoalMet(for: goal, on: day, modelContext: modelContext)
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

    var weeks: [GoalWidgetData.WeeklyGridData.Week] = []

    for weekOffset in 0..<20 {
      guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start,
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.end else {
        continue
      }

      let isCurrentWeek = weekOffset == 0

      // Check if week is within goal's active period
      guard goal.isDateWithinHabit(date: startOfWeek) else {
        weeks.append(
          GoalWidgetData.WeeklyGridData.Week(
            id: weekOffset,
            isComplete: nil,
            isCurrentWeek: isCurrentWeek,
            monthLabel: nil
          )
        )
        continue
      }

      // Fetch total quantity for the week
      let dateRange = DateRange(startOfWeek, endOfWeek)
      let quantity = await goal.targetMetric.fetchTotalQuantity(for: dateRange)
      let goalMet = goal.quantityMeetsGoal(quantity)

      // Add month label if this is the first week of a month
      let monthLabel = calendar.component(.weekOfMonth, from: startOfWeek) == 1
        ? startOfWeek.formatted(.dateTime.month(.abbreviated))
        : nil

      weeks.append(
        GoalWidgetData.WeeklyGridData.Week(
          id: weekOffset,
          isComplete: goalMet,
          isCurrentWeek: isCurrentWeek,
          monthLabel: monthLabel
        )
      )
    }

    return GoalWidgetData.WeeklyGridData(weeks: weeks)
  }

  /// Calculate monthly grid completion data (12 months)
  private func calculateMonthlyGridData(for goal: Habit, modelContext: ModelContext) async -> GoalWidgetData.MonthlyGridData {
    let calendar = Calendar.current
    let today = Date()

    var months: [GoalWidgetData.MonthlyGridData.Month] = []

    for monthOffset in 0..<12 {
      guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: today),
            let startOfMonth = calendar.dateInterval(of: .month, for: monthStart)?.start,
            let endOfMonth = calendar.dateInterval(of: .month, for: monthStart)?.end else {
        continue
      }

      let isCurrentMonth = monthOffset == 0
      let monthLabel = startOfMonth.formatted(.dateTime.month(.abbreviated))

      // Check if month is within goal's active period
      guard goal.isDateWithinHabit(date: startOfMonth) else {
        months.append(
          GoalWidgetData.MonthlyGridData.Month(
            id: monthOffset,
            isComplete: nil,
            isCurrentMonth: isCurrentMonth,
            monthLabel: monthLabel
          )
        )
        continue
      }

      // Fetch total quantity for the month
      let dateRange = DateRange(startOfMonth, endOfMonth)
      let quantity = await goal.targetMetric.fetchTotalQuantity(for: dateRange)
      let goalMet = goal.quantityMeetsGoal(quantity)

      months.append(
        GoalWidgetData.MonthlyGridData.Month(
          id: monthOffset,
          isComplete: goalMet,
          isCurrentMonth: isCurrentMonth,
          monthLabel: monthLabel
        )
      )
    }

    return GoalWidgetData.MonthlyGridData(months: months)
  }

  /// Calculate yearly grid completion data (5 years)
  private func calculateYearlyGridData(for goal: Habit, modelContext: ModelContext) async -> GoalWidgetData.YearlyGridData {
    let calendar = Calendar.current
    let today = Date()

    var years: [GoalWidgetData.YearlyGridData.Year] = []

    for yearOffset in 0..<5 {
      guard let yearStart = calendar.date(byAdding: .year, value: -yearOffset, to: today),
            let startOfYear = calendar.dateInterval(of: .year, for: yearStart)?.start,
            let endOfYear = calendar.dateInterval(of: .year, for: yearStart)?.end else {
        continue
      }

      let isCurrentYear = yearOffset == 0
      let yearLabel = startOfYear.formatted(.dateTime.year())

      // Check if year is within goal's active period
      guard goal.isDateWithinHabit(date: startOfYear) else {
        years.append(
          GoalWidgetData.YearlyGridData.Year(
            id: yearOffset,
            isComplete: nil,
            isCurrentYear: isCurrentYear,
            yearLabel: yearLabel
          )
        )
        continue
      }

      // Fetch total quantity for the year
      let dateRange = DateRange(startOfYear, endOfYear)
      let quantity = await goal.targetMetric.fetchTotalQuantity(for: dateRange)
      let goalMet = goal.quantityMeetsGoal(quantity)

      years.append(
        GoalWidgetData.YearlyGridData.Year(
          id: yearOffset,
          isComplete: goalMet,
          isCurrentYear: isCurrentYear,
          yearLabel: yearLabel
        )
      )
    }

    return GoalWidgetData.YearlyGridData(years: years)
  }

  /// Check if a goal was met on a specific day
  private func checkGoalMet(for goal: Habit, on date: Date, modelContext: ModelContext) async -> Bool {
    // Check if the date is within the goal's active period
    guard goal.isDateWithinHabit(date: date) else {
      return false
    }

    // Create date range for the specific day
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.endOfDay(for: date)

    let dateRange = DateRange(startOfDay, endOfDay)

    // Fetch the total quantity for this day from HealthKit
    let quantity = await goal.targetMetric.fetchTotalQuantity(for: dateRange)

    // Check if the quantity meets the goal
    return goal.quantityMeetsGoal(quantity)
  }
}

