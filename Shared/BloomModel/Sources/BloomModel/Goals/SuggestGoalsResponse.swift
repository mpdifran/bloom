//
//  SuggestGoalsResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation

public struct SuggestGoalsResponse: Codable, Equatable, Sendable {
  public let goals: [SuggestedGoal]
  public let reminders: [SuggestedReminder]
  public let thoughtProcess: [String]

  public init(
    goals: [SuggestedGoal],
    reminders: [SuggestedReminder],
    thoughtProcess: [String]
  ) {
    self.goals = goals
    self.reminders = reminders
    self.thoughtProcess = thoughtProcess
  }
}
