//
//  ProposedGoalsResult.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-01.
//

import Foundation

struct ProposedGoalsResult: Equatable, Sendable {
  var goals: [ProposedGoal]
  var todos: [ProposedToDo]
}
