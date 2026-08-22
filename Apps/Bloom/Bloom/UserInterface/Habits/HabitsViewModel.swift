//
//  HabitsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

import SwiftUI
import DataContainer
import TelemetryDeck
import HealthKit
import SwiftData

@MainActor
final class HabitsViewModel: ObservableObject {
  static let shared = HabitsViewModel()

  @Published var shouldUpdateSuggestedHabits = false

  private var lastHabitRefreshDate: Date? {
    didSet {
      UserDefaults.group.set(lastHabitRefreshDate, forKey: "HabitsViewModel.lastHabitRefreshDate")
      checkUpdateSuggestedHabits()
    }
  }

  let modelContext = ModelContext(ContainerHolder.shared.container)

  init() {
    if let date = UserDefaults.group.object(forKey: "HabitsViewModel.lastHabitRefreshDate") as? Date {
      lastHabitRefreshDate = date
    }
  }
}

extension HabitsViewModel {

  func checkUpdateSuggestedHabits() {
    guard let lastHabitRefreshDate else {
      shouldUpdateSuggestedHabits = true
      return
    }

    let mondayMorning = Calendar.current.mondayMorning(for: .now) ?? .distantPast

    shouldUpdateSuggestedHabits = mondayMorning > lastHabitRefreshDate
  }

  func alternateTargetMetrics(for proposedHabit: ProposedGoal) async -> [TargetMetric] {
    let alternativeTargetMetrics = proposedHabit.targetMetric.related

    guard alternativeTargetMetrics.isNotEmpty else { return [] }

    do {
      let modelActor = HabitModelActor.standard()
      let existingTargetMetrics = try await modelActor.fetchActiveHabits(isSuggested: false).map(\.targetMetric).asSet()

      return alternativeTargetMetrics.filter({ !existingTargetMetrics.contains($0) })
    } catch {
      print(error)
    }
    return []
  }

  func createHabit(from proposedGoal: ProposedGoal, isSuggested: Bool) -> Habit {
    Habit(
      targetMetric: proposedGoal.targetMetric,
      timePeriod: proposedGoal.timePeriod,
      value: proposedGoal.value,
      unitString: proposedGoal.unitString,
      startDate: .now,
      isSuggested: isSuggested,
      isUserEdited: proposedGoal.hasUserEdited,
      vitalKind: proposedGoal.vitalKind,
      context: proposedGoal.context
    )
  }

  func apply(proposedGoals: [ProposedGoal]) throws {
    try modelContext.savingTransaction {
      for proposedGoal in proposedGoals {
        let existingHabits = try modelContext.fetchActiveHabits(for: proposedGoal.targetMetric)
        existingHabits.forEach {
          $0.endDate = .now
        }

        let habit = createHabit(from: proposedGoal, isSuggested: true)
        modelContext.insert(habit)
      }
    }

    // Update widget cache and observer
    Task {
      await GoalWidgetCacheManager.shared.updateCache()
      await GoalWidgetHealthObserver.shared.startObserving()
    }
  }

  func resetHabitCheckDate() {
    lastHabitRefreshDate = nil
  }

  func update(
    timePeriod: GoalTimePeriod,
    value: Double,
    unit: HKUnit,
    for habit: Habit
  ) throws -> Habit {
    guard let fetchedHabit = try modelContext.fetchHabit(id: habit.id) else { throw NSError(description: String(localized: "There was a problem updating this habit.", comment: "Error shown when saving an edited goal fails")) }

    let updatedHabit: Habit
    let isUserEdited: Bool
    if !fetchedHabit.isUserEdited {
      isUserEdited = !fetchedHabit.value.isWithinRange(of: value, precision: 1)
    } else {
      isUserEdited = true
    }

    if Calendar.current.isDateInToday(fetchedHabit.startDate) {
      fetchedHabit.timePeriod = timePeriod
      fetchedHabit.value = value
      fetchedHabit.unitString = unit.unitString
      fetchedHabit.isUserEdited = isUserEdited
      updatedHabit = fetchedHabit
    } else {
      let newHabit = habit.duplicate()

      fetchedHabit.endDate = .now

      newHabit.startDate = .now
      newHabit.timePeriod = timePeriod
      newHabit.value = value
      newHabit.unitString = unit.unitString
      newHabit.isUserEdited = isUserEdited

      modelContext.insert(newHabit)

      updatedHabit = newHabit
    }

    try modelContext.save()

    // Update widget cache and observer
    Task {
      await GoalWidgetCacheManager.shared.updateCache()
      await GoalWidgetHealthObserver.shared.startObserving()
    }

    return updatedHabit
  }

  func delete(_ habit: Habit) throws {
    guard let fetchedHabit = try modelContext.fetchHabit(id: habit.id) else { return }

    if Calendar.current.isDateInToday(fetchedHabit.startDate) {
      modelContext.delete(fetchedHabit)
    } else {
      fetchedHabit.endDate = .now
    }

    try modelContext.save()

    // Update widget cache and observer
    Task {
      await GoalWidgetCacheManager.shared.updateCache()
      await GoalWidgetHealthObserver.shared.startObserving()
    }
  }
}
