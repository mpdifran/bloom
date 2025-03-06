//
//  HabitDetailsViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-06.
//

import SwiftUI
import HealthKit
import DataContainer

extension HabitDetailsView {
  @MainActor @Observable
  final class ViewModel {
    var habit: Habit
    var todayValue: HKQuantity
    var dailySamples = [DateQuantitySample]()
    var averageValue: HKQuantity?
    var dayStats = [Calendar.Weekday: Double]()
    var habitGridModel = HabitGridModel()
    var allSamplesTwelveWeeks = [DateQuantitySample]()
    var weekQuantitySamples = [WeekQuantitySamples]() {
      didSet { Task { await loadHabitGridModel() } }
    }

    init(habit: Habit) {
      self.habit = habit
      self.todayValue = HKQuantity(unit: habit.unit, doubleValue: 0)

      observeChanges()
    }

    private var hasLoadedTodayAtLeastOnce = false
    private var observationHandler: HKObserverQueryHandle?
  }
}

private extension HabitDetailsView.ViewModel {

  func observeChanges() {
    observationHandler = HealthManager.shared.healthStore.observeChanges(
      sampleTypes: habit.targetMetric.sampleTypes,
      startDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    ) { [weak self] in
      guard await self?.hasLoadedTodayAtLeastOnce == true else { return }

      await self?.loadTodayValue()
      await self?.loadGoalHistory()
    }
  }
}

extension HabitDetailsView.ViewModel {

  func habitUnit() -> HKUnit {
    habit.unit
  }

  func targetMetric() -> TargetMetric {
    habit.targetMetric
  }

  nonisolated func loadTodayValue() async {
    let quantity = await targetMetric().fetchTotalQuantity(for: .today())

    await MainActor.run {
      self.todayValue = quantity
      self.hasLoadedTodayAtLeastOnce = true
    }
  }

  nonisolated func loadGoalHistory() async {
    let targetMetric = await targetMetric()
    let unit = await habitUnit()

    let twelveWeeksSamples = await targetMetric.fetchCollatedDailyQuantity(
      unit: unit,
      dateRange: .trailingWeeksFromEndOfToday(12)
    )
    let samples = await targetMetric.fetchCollatedDailyQuantity(
      unit: unit,
      dateRange: .trailingWeeksFromEndOfToday(30)
    )

    let currentWeekOfYear = Calendar.current.weekOfYear(for: .now) ?? 52
    let groupedByWeekSamples = samples.grouped { sample in
      guard let weekOfYear = Calendar.current.weekOfYear(for: sample.date) else { return -1 }

      // The week IDs always need to be 0 on the right and a positive incrementing number to the left for the animation to work correctly.
      if currentWeekOfYear < weekOfYear {
        return currentWeekOfYear - weekOfYear + 52
      }
      return currentWeekOfYear - weekOfYear
    }

    let weekSamples = groupedByWeekSamples.compactMap { (key, samples) -> WeekQuantitySamples? in
      guard
        let sample = samples.first,
        key >= 0,
        let referenceDate = Calendar.current.startOfWeek(for: sample.date)
      else { return nil }

      return WeekQuantitySamples(
        id: key,
        referenceDate: referenceDate,
        samples: samples
      )
    }.sorted(keyPath: \.referenceDate)

    var statsIntermediate = [Calendar.Weekday: [Double]]()
    for sample in twelveWeeksSamples {
      guard let weekday = Calendar.current.weekday(for: sample.date) else { continue }

      statsIntermediate[weekday, default: []].append(sample.quantity.doubleValue(for: unit))
    }
    var stats = [Calendar.Weekday: Double]()
    for weekday in statsIntermediate.keys {
      stats[weekday] = statsIntermediate[weekday]?.average(keyPath: \.self) ?? 0
    }
    let statsConstant = stats

    let averageValue = twelveWeeksSamples.map({ $0.quantity.doubleValue(for: unit) }).average(keyPath: \.self)
    let averageQuantity = HKQuantity(unit: unit, doubleValue: averageValue)

    await MainActor.run {
      self.allSamplesTwelveWeeks = twelveWeeksSamples
      self.weekQuantitySamples = weekSamples
      self.dayStats = statsConstant
      self.dailySamples = samples.suffix(30)
      self.averageValue = averageQuantity
    }
  }

  nonisolated func loadHabitGridModel() async {
    let targetMetric = await targetMetric()

    let context = ContainerHolder.shared.createContext()

    let habitHistory: [Habit]
    do {
      habitHistory = try context.fetchHabits(for: targetMetric)
    } catch {
      print(error)
      return
    }

    let oldestHabit = habitHistory.first

    var weeks = await weekQuantitySamples.map { weekSamples in
      let todayIndex = weekSamples.samples.firstIndex(where: { Calendar.current.isDateInToday($0.date) })

      let isCompleteArray = weekSamples.samples.map { sample in
        let referenceHabit: Habit
        if let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: sample.date) }) {
          referenceHabit = habit
        } else if let oldestHabit, sample.date < oldestHabit.startDate {
          referenceHabit = oldestHabit
        } else {
          return false
        }
        return referenceHabit.quantityMeetsGoal(sample.quantity)
      }

      return HabitGridModel.Week(
        id: weekSamples.id,
        isComplete: isCompleteArray,
        todayIndex: todayIndex
      )
    }

    if weeks.count < 30 {
      var earliestId = weeks.first?.id ?? 0

      let remainingAdditions = 30 - weeks.count

      for _ in 0 ..< remainingAdditions {
        earliestId -= 1
        let week = HabitGridModel.Week(id: earliestId, isComplete: Array(repeating: false, count: 7))
        weeks.insert(week, at: 0)
      }
    }

    let model = HabitGridModel(weeks: weeks)

    await MainActor.run {
      self.habitGridModel = model
    }
  }
}
