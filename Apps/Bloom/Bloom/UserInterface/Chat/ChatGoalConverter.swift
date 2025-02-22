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

  func convertGoalData() async -> CurrentGoalsData? {
    do {
      let activeGoals = try await modelActor.fetchActiveHabits()

      let targetMetrics = activeGoals.compactMap { goal -> TargetMetric? in
        guard goal.targetMetric.metric != nil else { return nil }

        return goal.targetMetric
      }

      var goalSummaries = [GoalSummary]()
      for targetMetric in targetMetrics {
        let summaries = try await createGoalSummaries(for: targetMetric)
        goalSummaries.append(contentsOf: summaries)
      }

      return CurrentGoalsData(currentGoals: goalSummaries)
    } catch {
      print(error)
    }
    return nil
  }
}

private extension ChatGoalConverter {

  func createGoalSummaries(for targetMetric: TargetMetric) async throws -> [GoalSummary] {

    guard let metric = targetMetric.metric else { return [] }

    let habits = try await modelActor.fetchHabits(for: targetMetric)
    let dateRange = DateRange.trailingDaysFromNow(.goalHistoryDays)

    let samples = await targetMetric.fetchCollatedDailyQuantity(
      unit: targetMetric.defaultUnit,
      dateRange: dateRange
    )

    var goalSummaries = [GoalSummary]()
    var currentHabit: HabitDTO?
    var currentDates = [String]()
    Calendar.current.iterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
      if currentHabit?.isDateWithinHabit(date: date) != true {
        let newHabit = habits.first { $0.isDateWithinHabit(date: date) }
        if let currentHabit, (currentHabit.value != newHabit?.value || currentHabit.unitString != newHabit?.unitString) {
          goalSummaries.append(
            createGoalSummary(from: currentHabit, metric: metric, dates: currentDates)
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
      goalSummaries.append(
        createGoalSummary(from: currentHabit, metric: metric, dates: currentDates)
      )
    }

    return goalSummaries
  }
}

func createGoalSummary(
  from habit: HabitDTO,
  metric: SuggestedGoal.Metric,
  dates: [String]
) -> GoalSummary {
  GoalSummary(
    metric: metric,
    value: habit.value,
    unit: habit.unit.sensibleUnitString,
    startDate: habit.startDate,
    endDate: habit.endDate,
    goalMetOnDates: dates
  )
}

extension TargetMetric {
  var metric: SuggestedGoal.Metric? {
    switch self {
    case .calories, .proteinIntake, .none:
      return nil
    case .waterIntake:
      return .waterIntake
    case .fiberIntake:
      return .fiberIntake
    case .timeInDaylight:
        return nil // TODO: We need to figure out how to handle the fact that not all watches measure this.
    case .meditationMinutes:
      return  .meditationMinutes
    case .exerciseMinutes:
      return .exerciseMinutes
    case .stepCount:
      return .stepCount
    case .walkingRunningDistance:
      return .walkingRunningDistance
    case .runDistance:
      return .runDistance
    case .runDuration:
      return .runDuration
    case .bikeDistance:
      return .bikeDistance
    case .bikeDuration:
      return .bikeDuration
    case .targetHeartRateZone1:
      return .targetHeartRateZone1Minutes
    case .targetHeartRateZone2:
      return .targetHeartRateZone2Minutes
    case .targetHeartRateZone3:
      return .targetHeartRateZone3Minutes
    case .targetHeartRateZone4:
      return .targetHeartRateZone4Minutes
    case .targetHeartRateZone5:
      return .targetHeartRateZone5Minutes
    @unknown default:
      return nil
    }
  }
}
