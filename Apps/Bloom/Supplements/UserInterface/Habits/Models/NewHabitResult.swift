//
//  NewHabitResult.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-30.
//

import Foundation
import DataContainer

struct NewHabitResult: Sendable, Hashable {
  var proposedGoals: [ProposedHabit]
  var proposedToDos: [ProposedToDo]

  init(
    proposedGoals: [ProposedHabit] = [],
    proposedToDos: [ProposedToDo] = []
  ) {
    self.proposedGoals = proposedGoals
    self.proposedToDos = proposedToDos
  }
}

extension NewHabitResult {
  mutating func appendNewTargets(result: NewHabitResult) {
    let newGoals = result.proposedGoals.filter({ goal in
      !proposedGoals.contains(where: { $0.targetMetric == goal.targetMetric })
    })
    proposedGoals.append(contentsOf: newGoals)

    let newToDos = result.proposedToDos.filter({ toDo in
      !proposedToDos.contains(where: { $0.todoKind == toDo.todoKind })
    })
    proposedToDos.append(contentsOf: newToDos)
  }

  func contains(_ targetMetric: TargetMetric) -> Bool {
    allTargetMetrics.contains(targetMetric)
  }

  var allTargetMetrics: [TargetMetric] {
    proposedGoals.map { $0.targetMetric }
  }

  var allVitalKinds: [VitalModel.Kind] {
    proposedGoals.compactMap(\.vitalKind) +
    proposedToDos.compactMap(\.vitalKind)
  }
}
