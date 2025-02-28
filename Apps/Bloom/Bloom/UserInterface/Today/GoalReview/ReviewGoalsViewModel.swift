//
//  ReviewGoalsViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import SwiftUI
import DataContainer
import BloomFoundation

extension ReviewGoalsView {
  @MainActor @Observable
  final class ViewModel {
    let modelActor = HabitModelActor.standard()

    var goalLookbackDetails = [GoalLookbackDetails]()
  }
}

extension ReviewGoalsView.ViewModel {

  func loadGoalHistory() async {
    do {
      let activeGoals = try await modelActor.fetchActiveHabits()
      let dateRange = DateRange.trailingDaysFromNow(7)

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
      self.goalLookbackDetails = goalLookbacks
    } catch {
      print(error)
    }
  }
}
