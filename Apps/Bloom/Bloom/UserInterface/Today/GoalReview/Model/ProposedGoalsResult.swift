//
//  ProposedGoalsResult.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-01.
//

import Foundation

struct ProposedGoalsResult: Equatable, Sendable {
  var goals: [ProposedGoal]
  var removedGoals: [ProposedGoal]
  var todos: [ProposedToDo]

  init(
    goals: [ProposedGoal] = [],
    removedGoals: [ProposedGoal] = [],
    todos: [ProposedToDo] = []
  ) {
    self.goals = goals
    self.removedGoals = removedGoals
    self.todos = todos
  }

  var isEmpty: Bool {
    goals.isEmpty && removedGoals.isEmpty && todos.isEmpty
  }
}
