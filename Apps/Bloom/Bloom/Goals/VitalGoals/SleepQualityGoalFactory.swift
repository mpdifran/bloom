//
//  SleepQualityGoalFactory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-12.
//

import Foundation
import DataContainer

final class SleepQualityGoalFactory: Sendable {
  let goalFactory = GoalFactory()
  let vitalKind: VitalModel.Kind = .sleepQuality
}

extension SleepQualityGoalFactory {

  func createGoals() async -> [ProposedGoal] {
    [
      await goalFactory.createHabit(
        targetMetric: .meditationMinutes,
        unit: .minute(),
        vitalKind: vitalKind,
        context: "Meditating before bed is a great way to prepare for a good nights sleep."
      )
    ]
  }
}
