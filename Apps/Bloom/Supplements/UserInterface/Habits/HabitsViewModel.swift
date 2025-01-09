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

  func generateProposedHabits() async -> NewHabitResult {
    await HabitsFactory.shared.generateProposedHabits()
  }

  func alternateTargetMetrics(for proposedHabit: ProposedHabit) async -> [TargetMetric] {
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

  func generateProposedHabit(
    for targetMetric: TargetMetric,
    vitalKind: VitalModel.Kind?
  ) async -> ProposedHabit {
    await HabitsFactory.shared.generateProposedHabit(
      for: targetMetric,
      vitalKind: vitalKind
    )
  }

  func performSave(
    proposedGoals: [ProposedHabit],
    proposedToDos: [ProposedToDo]
  ) throws {
    for existingHabit in try modelContext.fetchActiveHabits(isSuggested: true) {
      existingHabit.endDate = .now
    }

    for proposedGoal in proposedGoals {
      // If this is replacing an existing goal, let's end the existing one.
      if
        let habitID = proposedGoal.habitID,
        let existingHabit = try modelContext.fetchHabit(id: habitID)
      {
        existingHabit.endDate = .now
      }

      // If the user added this habit, let's end it.
      let activeMatchingHabits = try modelContext.fetchActiveHabits(for: proposedGoal.targetMetric)
      for habit in activeMatchingHabits {
        habit.endDate = .now
      }
      
      let habit = Habit(
        targetMetric: proposedGoal.targetMetric,
        value: proposedGoal.value,
        unitString: proposedGoal.unitString,
        startDate: .now,
        isSuggested: proposedGoal.vitalKind != nil,
        isUserEdited: proposedGoal.hasUserEdited,
        vitalKind: proposedGoal.vitalKind,
        context: proposedGoal.context
      )

      modelContext.insert(habit)
    }

    try modelContext.save()

    ToDoManager.shared.apply(proposedToDos: proposedToDos)

    lastHabitRefreshDate = .now
  }

  func resetHabitCheckDate() {
    lastHabitRefreshDate = nil
  }
}
