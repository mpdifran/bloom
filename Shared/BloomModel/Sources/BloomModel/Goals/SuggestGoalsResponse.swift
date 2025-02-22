//
//  SuggestGoalsResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation

public struct SuggestGoalsResponse: Codable, Equatable, Sendable {
  public let summary: String?
  public let goals: [SuggestedGoal]

  public init(
    summary: String?,
    goals: [SuggestedGoal]
  ) {
    self.summary = summary
    self.goals = goals
  }
}
