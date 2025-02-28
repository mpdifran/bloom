//
//  HabitGoalStatisticsCalculator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-02.
//

import Foundation
import HealthKit
import DataContainer
import BloomFoundation

enum HabitGoalStatisticsCalculator {

  static func calculateStatistics(for habit: HabitDTO) async -> HabitGoalStatistics {
    await calculateStatistics(for: habit.targetMetric, unit: habit.unit)
  }

  static func calculateStatistics(
    for targetMetric: TargetMetric,
    unit: HKUnit
  ) async -> HabitGoalStatistics {

    let modelActor = HabitModelActor.standard()

    let habitHistory = (try? await modelActor.fetchHabits(for: targetMetric)) ?? []

    let samples = await targetMetric.fetchCollatedDailyQuantity(
      unit: unit,
      dateRange: .trailingWeeksFromNow(2)
    )

    var metGoalSamples = [HabitGoalStatistics.HabitSamplePair]()
    var missedGoalSamples = [HabitGoalStatistics.HabitSamplePair]()

    for sample in samples {
      let habit: HabitDTO

      if let timelineHabit = habitHistory.first(where: { $0.isDateWithinHabit(date: sample.date) }) {
        habit = timelineHabit
      } else if let oldestHabit = habitHistory.min(by: \.startDate) {
        habit = oldestHabit
      } else {
        continue
      }

      let sampleValue = sample.quantity

      if habit.quantityMeetsGoal(sampleValue, gracePercent: 0.05) {
        metGoalSamples.append(
          HabitGoalStatistics.HabitSamplePair(habit: habit, sample: sample)
        )
      } else {
        missedGoalSamples.append(
          HabitGoalStatistics.HabitSamplePair(habit: habit, sample: sample)
        )
      }
    }

    return HabitGoalStatistics(
      metGoalSamples: metGoalSamples,
      missedGoalSamples: missedGoalSamples
    )
  }

  static func calculateGoalMetHistory(
    targetMetric: TargetMetric,
    dateRange: DateRange
  ) async throws -> [HabitGoalMetSample] {
    let modelActor = HabitModelActor.standard()

    let goals = try await modelActor.fetchHabits(for: targetMetric)
    let samples = await targetMetric.fetchCollatedDailyQuantity(
      unit: targetMetric.defaultUnit,
      dateRange: dateRange
    )

    var goalMetSamples = [HabitGoalMetSample]()

    Calendar.current.iterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
      guard
        let goal = referenceGoal(date: date, goals: goals),
        let sample = samples.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
      else { return }

      let goalMet = goal.quantityMeetsGoal(sample.quantity)

      let goalMetSample = HabitGoalMetSample(date: date, goalMet: goalMet)
      goalMetSamples.append(goalMetSample)
    }

    return goalMetSamples
  }
}

private extension HabitGoalStatisticsCalculator {

  static func referenceGoal(date: Date, goals: [HabitDTO]) -> HabitDTO? {
    if let goal = goals.first(where: { $0.isDateWithinHabit(date: date) }) {
      return goal
    }
    if let oldestGoal = goals.min(by: { $0.startDate < $1.startDate }) {
      return oldestGoal
    }
    return nil
  }
}
