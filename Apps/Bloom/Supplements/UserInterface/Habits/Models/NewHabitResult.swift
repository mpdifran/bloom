//
//  NewHabitResult.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-30.
//

import Foundation
import DataContainer

struct NewHabitResult: Sendable, Hashable {
  var focusVitals: [FocusVital]
  var proposedGoals: [ProposedGoal]
  var proposedToDos: [ProposedToDo]

  init(
    focusVitals: [FocusVital] = [],
    proposedGoals: [ProposedGoal] = [],
    proposedToDos: [ProposedToDo] = []
  ) {
    self.focusVitals = focusVitals
    self.proposedGoals = proposedGoals
    self.proposedToDos = proposedToDos
  }
}

extension NewHabitResult {

  mutating func appendNewTargets(result: NewHabitResult) {
    let newFocusVitals = result.focusVitals.filter { focusVital in
      !focusVitals.contains(where: { $0.vitalKind == focusVital.vitalKind })
    }
    focusVitals.append(contentsOf: newFocusVitals)

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

  var allProposedGoals: [ProposedGoal] {
    focusVitals.compactMap({ $0.proposedGoals.first }) + proposedGoals
  }
}
