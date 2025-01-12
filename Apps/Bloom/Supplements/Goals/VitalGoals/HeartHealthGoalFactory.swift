//
//  HeartHealthGoalFactory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-12.
//

import Foundation
import DataContainer

final class HeartHealthGoalFactory: Sendable {
  let goalFactory = GoalFactory()
  let vitalKind: VitalModel.Kind = .heartHealth
}

extension HeartHealthGoalFactory {

  func createGoals() async -> [ProposedGoal] {
    [
      await goalFactory.createHabit(
        targetMetric: .stepCount,
        unit: .count(),
        vitalKind: vitalKind,
        context: "Getting your steps in can help improve your heart health."
      ),
      await goalFactory.createHabit(
        targetMetric: .walkingRunningDistance,
        unit: .meterUnit(with: .kilo),
        vitalKind: vitalKind,
        context: "Walking or running more can help improve your heart health."
      ),
      await goalFactory.createHabit(
        targetMetric: .exerciseMinutes,
        unit: .minute(),
        vitalKind: vitalKind,
        context: "Getting any type of exercise will help keep your heart healthy."
      ),
    ]
  }
}
