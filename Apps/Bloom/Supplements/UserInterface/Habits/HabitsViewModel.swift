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
    await HabitsFactory.shared.generateProposedHabits(vitals: vitals)
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

  func performSave(newGoals: NewHabitResult) throws {

    // End all existing habits
    for existingHabit in try modelContext.fetchActiveHabits() {
      existingHabit.endDate = .now
    }

    var addedTargetMetrics = [TargetMetric]()

    // Add new goals
    for proposedGoal in newGoals.allProposedGoals {
      guard !addedTargetMetrics.contains(proposedGoal.targetMetric) else { continue }

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
      addedTargetMetrics.append(proposedGoal.targetMetric)
    }

    try modelContext.save()

    ToDoManager.shared.apply(proposedToDos: newGoals.proposedToDos)

    lastHabitRefreshDate = .now
  }

  func resetHabitCheckDate() {
    lastHabitRefreshDate = nil
  }
}
