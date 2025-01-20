//
//  StressLevelGoalFactory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-12.
//

import Foundation
import DataContainer

final class StressLevelGoalFactory: Sendable {
  let goalFactory = GoalFactory()
  let vitalKind: VitalModel.Kind = .stressLevels
}

extension StressLevelGoalFactory {

  func createGoals() async -> [ProposedGoal] {
    [
      await goalFactory.createHabit(
        targetMetric: .meditationMinutes,
        unit: .minute(),
        vitalKind: vitalKind,
        context: "Meditation is a great way to lower stress levels."
      )
    ]
  }
}
