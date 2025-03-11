//
//  BowelMovementGoalFactory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-12.
//

import Foundation
import DataContainer

final class BowelMovementGoalFactory: Sendable {
  let goalFactory = GoalFactory()
  let vitalKind: VitalModel.Kind = .bowelMovements
}

extension BowelMovementGoalFactory {

  func createGoals() async -> [ProposedGoal] {
    [
      await goalFactory.createHabit(
        targetMetric: .waterIntake,
        unit: .literUnit(with: .milli),
        vitalKind: vitalKind,
        context: "Staying hydrated can help make your bowel movements more regular."
      ),
      await goalFactory.createHabit(
        targetMetric: .fiberIntake,
        unit: .gram(),
        vitalKind: vitalKind,
        context: "Eating fiber can help make your bowel movements more regular."
      )
    ]
  }
}
