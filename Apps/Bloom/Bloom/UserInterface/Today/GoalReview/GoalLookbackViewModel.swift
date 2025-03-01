//
//  GoalLookbackViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import SwiftUI
import DataContainer
import BloomFoundation

extension GoalLookbackView {
  @MainActor @Observable
  final class ViewModel {
    private let modelActor = HabitModelActor.standard()
  }
}

extension GoalLookbackView.ViewModel {

  func loadGoalHistory() async -> [GoalLookbackDetails] {
    do {
      let activeGoals = try await modelActor.fetchActiveHabits()
      let dateRange = DateRange.trailingDaysFromEndOfYesterday(6)

      var goalLookbacks = [GoalLookbackDetails]()

      for goal in activeGoals {
        do {
          let history = try await HabitGoalStatisticsCalculator.calculateGoalMetHistory(
            targetMetric: goal.targetMetric,
            dateRange: dateRange
          )

          let details = GoalLookbackDetails(
            goal: goal,
            goalMetHistory: history
          )
          goalLookbacks.append(details)
        } catch {
          print(error)
        }
      }
      return goalLookbacks
    } catch {
      print(error)
    }
    return []
  }

  func proposeNewGoals() async throws -> ProposedGoalsResult {
    try await AIGoalManager.shared.proposeNewGoals()
  }
}
