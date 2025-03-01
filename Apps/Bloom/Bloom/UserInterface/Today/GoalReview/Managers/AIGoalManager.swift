//
//  AIGoalManager.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-01.
//

import Foundation
import DataContainer

final actor AIGoalManager {
  static let shared = AIGoalManager()

  private let modelActor = HabitModelActor.standard()
}

extension AIGoalManager {

  func proposeNewGoals() async throws -> ProposedGoalsResult {
    let healthData = try await ChatVitalConverter.shared.convertHealthDataString()
    let currentGoals = try await ChatGoalConverter.shared.convertGoalDataString()
    let response = try await NetworkRequester.shared.suggestGoals(healthData: healthData, currentGoals: currentGoals)

    var proposedGoals = [ProposedGoal]()
    for goal in response.goals {
      guard let habit = try await modelActor.fetchActiveHabits(for: goal.metric.targetMetric).first else { continue }

      let proposedGoal = ProposedGoal(
        habitID: habit.id,
        targetMetric: goal.metric.targetMetric,
        value: goal.value,
        suggestedValue: goal.value,
        previousValue: habit.value,
        unitString: habit.unitString,
        vitalKind: nil,
        context: goal.notes,
        hasUserEdited: false
      )
      proposedGoals.append(proposedGoal)
    }

    return ProposedGoalsResult(
      summary: response.summary,
      goals: proposedGoals
    )
  }
}
