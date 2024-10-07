//
//  NewHabitResult.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-30.
//

import Foundation
import DataContainer

struct NewHabitResult: Sendable, Hashable {
    var proposedFocusAreas: [ProposedHabit]
    var proposedHabits: [ProposedHabit]
    var proposedToDos: [ProposedToDo]

    init(
        proposedFocusAreas: [ProposedHabit] = [],
        proposedHabits: [ProposedHabit] = [],
        proposedToDos: [ProposedToDo] = []
    ) {
        self.proposedFocusAreas = proposedFocusAreas
        self.proposedHabits = proposedHabits
        self.proposedToDos = proposedToDos
    }
}

extension NewHabitResult {

    mutating func appendNewTargets(result: NewHabitResult) {
        let newFocusAreas = result.proposedFocusAreas.filter({ focusArea in
            !proposedFocusAreas.contains(where: { $0.targetMetric == focusArea.targetMetric })
        })
        proposedFocusAreas.append(contentsOf: newFocusAreas)
        let newHabits = result.proposedHabits.filter({ focusArea in
            !proposedHabits.contains(where: { $0.targetMetric == focusArea.targetMetric })
        })
        proposedHabits.append(contentsOf: newHabits)
        let newToDos = result.proposedToDos.filter({ focusArea in
            !proposedToDos.contains(where: { $0.todoKind == focusArea.todoKind })
        })
        proposedToDos.append(contentsOf: newToDos)
    }

    func contains(_ targetMetric: TargetMetric) -> Bool {
        allTargetMetrics.contains(targetMetric)
    }

    var allTargetMetrics: [TargetMetric] {
        proposedFocusAreas.map { $0.targetMetric } +
        proposedHabits.map { $0.targetMetric }
    }
}
