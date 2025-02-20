//
//  SuggestGoalsResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation

public struct SuggestGoalsResponse: Codable, Equatable, Sendable {
  public let goals: [SuggestedGoal]

  public init(goals: [SuggestedGoal]) {
    self.goals = goals
  }
}
