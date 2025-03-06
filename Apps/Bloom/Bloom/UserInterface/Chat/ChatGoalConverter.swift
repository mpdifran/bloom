//
//  ChatGoalConverter.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-21.
//

import Foundation
import DataContainer
import BloomFoundation
import BloomModel
import HealthKit

private extension Int {
  static let goalHistoryDays: Int = 30
}

final actor ChatGoalConverter {
  static let shared = ChatGoalConverter()

  private let modelActor = HabitModelActor.standard()

  private init() { }
}

extension ChatGoalConverter {

  func convertGoalDataString() async throws -> String {
    let goalsData = await convertGoalData()
    let jsonData = try JSONEncoder.bloomModel.encode(goalsData)
    return String(data: jsonData, encoding: .utf8) ?? "{}"
  }

  func convertGoalData() async -> CurrentGoalsData? {
    do {
      let activeGoals = try await modelActor.fetchActiveHabits()

      let targetMetrics = activeGoals.compactMap { goal -> TargetMetric? in
        guard goal.targetMetric.metric != nil else { return nil }

        return goal.targetMetric
      }

      var goalSummaries = [GoalSummary]()
      for targetMetric in targetMetrics {
        if let summary = try await createGoalSummary(for: targetMetric) {
          goalSummaries.append(summary)
        }
      }

      let metricSummaries = await createMetricSummaries()

      return CurrentGoalsData(
        currentGoals: goalSummaries,
        metricSummaries: metricSummaries
      )
    } catch {
      print(error)
    }
    return nil
  }
}

private extension ChatGoalConverter {

  func createGoalSummary(for targetMetric: TargetMetric) async throws -> GoalSummary? {

    guard let metric = targetMetric.metric else { return nil }

    let habits = try await modelActor.fetchHabits(for: targetMetric)
    let dateRange = DateRange.trailingDaysFromNow(.goalHistoryDays)

    let samples = await targetMetric.fetchCollatedDailyQuantity(
      unit: targetMetric.defaultUnit,
      dateRange: dateRange
    )

    var currentHabit: HabitDTO?
    var goalHistories = [GoalSummary.GoalHistory]()
    var currentDates = [String]()
    await Calendar.current.asyncIterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
      if currentHabit?.isDateWithinHabit(date: date) != true {
        let newHabit = habits.first { $0.isDateWithinHabit(date: date) }
        if let currentHabit, (currentHabit.value != newHabit?.value || currentHabit.unitString != newHabit?.unitString) {
          await goalHistories.append(
            GoalSummary.GoalHistory(
              goal: currentHabit.quantity.displayString(for: currentHabit.unit),
              lastSevenDaysGoalMet: currentDates
            )
          )
          currentDates = []
        }
        currentHabit = newHabit
      }

      guard let currentHabit else { return }
      guard let sample = samples.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return }

      if currentHabit.quantityMeetsGoal(sample.quantity) {
        currentDates.append(DateFormatter.justDateShort.string(from: date))
      }
    }

    if let currentHabit {
      await goalHistories.append(
        GoalSummary.GoalHistory(
          goal: currentHabit.quantity.displayString(for: currentHabit.unit),
          lastSevenDaysGoalMet: currentDates
        )
      )
    }

    return GoalSummary(metric: metric, history: goalHistories)
  }

  func createMetricSummaries() async -> [MetricSummary] {
    guard await ExternalHealthMetricPermissionManager.shared.getIsEnabled(for: .goalHistory) else {
      return []
    }

    var metricSummaries = [MetricSummary]()

    for metric in SuggestedGoal.Metric.allCases {
      let targetMetric = metric.targetMetric
      let unit = targetMetric.defaultUnit

      let sevenDayAverage = await targetMetric.fetchDailyAverage(
        unit: unit,
        dateRange: .trailingDaysFromEndOfYesterday(7)
      )
      let thirtyDayAverage = await targetMetric.fetchDailyAverage(
        unit: unit,
        dateRange: .trailingDaysFromEndOfYesterday(30)
      )
      let sixtyDayAverage = await targetMetric.fetchDailyAverage(
        unit: unit,
        dateRange: .trailingDaysFromEndOfYesterday(60)
      )

      let summary = await MetricSummary(
        metric: metric,
        sevenDayAverage: sevenDayAverage.displayString(for: unit),
        thirtyDayAverage: thirtyDayAverage.displayString(for: unit),
        sixtyDayAverage: sixtyDayAverage.displayString(for: unit)
      )
      metricSummaries.append(summary)
    }

    return metricSummaries
  }
}
