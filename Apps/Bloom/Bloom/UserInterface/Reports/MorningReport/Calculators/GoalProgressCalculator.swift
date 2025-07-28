//
//  GoalProgressCalculator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import DataContainer
import BloomFoundation
import HealthKit
import CoreHealth

final actor GoalProgressCalculator {
  static let shared = GoalProgressCalculator()

  private let modelActor = HabitModelActor.standard()

  private init() { }
}

extension GoalProgressCalculator {

  func calculateGoalProgressString(for date: Date) async throws -> String {
    let progressData = try await calculateGoalProgress(for: date)
    let jsonData = try JSONEncoder.bloomModel.encode(progressData)
    return String(data: jsonData, encoding: .utf8) ?? "{}"
  }

  func calculateGoalProgress(for date: Date) async throws -> GoalProgressData {
    let activeGoals = try await modelActor.fetchActiveHabits()

    var progressItems = [GoalProgress]()

    for goal in activeGoals {
      guard let metric = goal.targetMetric.metric else { continue }

      let currentQuantity = await fetchActualQuantity(for: goal, on: date)
      let progressQuantity = await fetchProgressQuantity(for: goal, on: date)
      let goalQuantity = goal.quantity

      let currentValueString = await currentQuantity.displayString(for: goal.unit, formatter: goal.targetMetric.preferredFormatter)
      let progressMadeYesterdayValueString = await progressQuantity.displayString(for: goal.unit, formatter: goal.targetMetric.preferredFormatter)
      let goalValueString = await goalQuantity.displayString(for: goal.unit, formatter: goal.targetMetric.preferredFormatter)

      let progressPercentage = calculateProgressPercentage(
        actual: currentQuantity,
        goal: goalQuantity,
        unit: goal.unit
      )

      let progressMadeYesterdayPercentage = calculateProgressPercentage(
        actual: progressQuantity,
        goal: goalQuantity,
        unit: goal.unit
      )

      let goalMet = goal.quantityMeetsGoal(currentQuantity)

      let progress = GoalProgress(
        metric: metric.rawValue,
        timePeriod: goal.timePeriod.name,
        goalValue: goalValueString,
        currentValue: currentValueString,
        progressMadeYesterdayValue: progressMadeYesterdayValueString,
        progressPercentage: progressPercentage,
        progressMadeYesterdayPercentage: progressMadeYesterdayPercentage,
        goalMet: goalMet
      )

      progressItems.append(progress)
    }

    return GoalProgressData(
      date: date,
      goalProgress: progressItems
    )
  }
}

private extension GoalProgressCalculator {

  func fetchProgressQuantity(for goal: HabitDTO, on date: Date) async -> HKQuantity {
    let dateRange = DateRange.duringDay(date)
    return await goal.targetMetric.fetchTotalQuantity(for: dateRange)
  }

  func fetchActualQuantity(for goal: HabitDTO, on date: Date) async -> HKQuantity {
    let dateRange: DateRange
    let endDate = Calendar.current.endOfDay(for: date)

    switch goal.timePeriod {
    case .daily:
      let startDate = Calendar.current.startOfDay(for: date)
      dateRange = DateRange(startDate, endDate)
    case .weekly:
      let weekStart = Calendar.current.startOfWeek(for: date) ?? date
      dateRange = DateRange(weekStart, endDate)
    case .monthly:
      let monthStart = Calendar.current.startOfMonth(for: date) ?? date
      dateRange = DateRange(monthStart, endDate)
    case .yearly:
      let yearStart = Calendar.current.startOfYear(for: date) ?? date
      dateRange = DateRange(yearStart, endDate)
    @unknown default:
      let startDate = Calendar.current.startOfDay(for: date)
      dateRange = DateRange(startDate, endDate)
    }

    return await goal.targetMetric.fetchTotalQuantity(for: dateRange)
  }


  func calculateProgressPercentage(actual: HKQuantity, goal: HKQuantity, unit: HKUnit) -> Double {
    let actualValue = actual.doubleValue(for: unit)
    let goalValue = goal.doubleValue(for: unit)

    guard goalValue > 0 else { return 0 }

    return (actualValue / goalValue) * 100
  }
}

