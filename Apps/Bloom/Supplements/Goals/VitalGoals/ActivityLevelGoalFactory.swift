//
//  ActivityLevelGoalFactory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-12.
//

import Foundation
import DataContainer

final class ActivityLevelGoalFactory: Sendable {
  let goalFactory = GoalFactory()
  let vitalKind: VitalModel.Kind = .activityLevel
}

extension ActivityLevelGoalFactory {

  func createGoals() async -> [ProposedGoal] {
    [
      await goalFactory.createHabit(
        targetMetric: .stepCount,
        unit: .count(),
        vitalKind: vitalKind,
        context: "Getting your steps in is an easy way to increase your activity level."
      ),
      await goalFactory.createHabit(
        targetMetric: .walkingRunningDistance,
        unit: .meterUnit(with: .kilo),
        vitalKind: vitalKind,
        context: "Walking or running more can help increase your daily activity level."
      )
    ]
  }
}
