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

  func generateProposedHabits(vitals: [VitalModel]) async -> NewHabitResult {
    await GoalsFactory.shared.generateProposedHabits(vitals: vitals)
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

  func performSave(newGoals: NewHabitResult, isAI: Bool = false) throws {

    // End all existing habits
    for existingHabit in try modelContext.fetchActiveHabits() {
      existingHabit.endDate = .now
    }

    var addedTargetMetrics = [TargetMetric]()

    for focusVital in newGoals.focusVitals {
      guard
        let proposedGoal = focusVital.proposedGoals.first,
        !addedTargetMetrics.contains(proposedGoal.targetMetric)
      else { continue }

      let habit = createHabit(from: proposedGoal, isSuggested: true)
      modelContext.insert(habit)
      addedTargetMetrics.append(proposedGoal.targetMetric)

      TelemetryDeck.signal(
        "Update Goal",
        parameters: [
          "userAdded": "false",
          "vitalKind": focusVital.vitalKind.name,
          "goalKind": proposedGoal.targetMetric.name,
          "value": proposedGoal.value.format(using: .twoDecimalPlaces),
          "suggestedValue": proposedGoal.suggestedValue.format(using: .twoDecimalPlaces),
          "originalValue": proposedGoal.previousValue?.format(using: .twoDecimalPlaces) ?? "None",
          "isAI": isAI ? "true" : "false"
        ],
        floatValue: proposedGoal.value
      )
    }

    for proposedGoal in newGoals.proposedGoals {
      guard !addedTargetMetrics.contains(proposedGoal.targetMetric) else { continue }

      let habit = createHabit(from: proposedGoal, isSuggested: false)
      modelContext.insert(habit)
      addedTargetMetrics.append(proposedGoal.targetMetric)

      TelemetryDeck.signal(
        "Update Goal",
        parameters: [
          "userAdded": "true",
          "goalKind": proposedGoal.targetMetric.name,
          "value": proposedGoal.value.format(using: .twoDecimalPlaces),
          "suggestedValue": proposedGoal.suggestedValue.format(using: .twoDecimalPlaces),
          "originalValue": proposedGoal.previousValue?.format(using: .twoDecimalPlaces) ?? "None",
          "isAI": isAI ? "true" : "false"
        ],
        floatValue: proposedGoal.value
      )
    }

    try modelContext.save()

    ToDoManager.shared.apply(proposedToDos: newGoals.proposedToDos)

    lastHabitRefreshDate = .now

    TelemetryDeck.signal("User Goal Count", floatValue: Double(addedTargetMetrics.count))
  }

  func createHabit(from proposedGoal: ProposedGoal, isSuggested: Bool) -> Habit {
    Habit(
      targetMetric: proposedGoal.targetMetric,
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
  }

  func resetHabitCheckDate() {
    lastHabitRefreshDate = nil
  }

  func update(value: Double, unit: HKUnit, for habit: Habit) throws -> Habit {
    guard let fetchedHabit = try modelContext.fetchHabit(id: habit.id) else { throw NSError(description: "There was a problem updating this habit.") }

    let updatedHabit: Habit
    let isUserEdited: Bool
    if !fetchedHabit.isUserEdited {
      isUserEdited = !fetchedHabit.value.isWithinRange(of: value, precision: 1)
    } else {
      isUserEdited = true
    }

    if Calendar.current.isDateInToday(fetchedHabit.startDate) {
      fetchedHabit.value = value
      fetchedHabit.unitString = unit.unitString
      fetchedHabit.isUserEdited = isUserEdited
      updatedHabit = fetchedHabit
    } else {
      let newHabit = habit.duplicate()

      fetchedHabit.endDate = .now

      newHabit.startDate = .now
      newHabit.value = value
      newHabit.unitString = unit.unitString
      newHabit.isUserEdited = isUserEdited

      modelContext.insert(newHabit)

      updatedHabit = newHabit
    }

    try modelContext.save()

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
  }
}
