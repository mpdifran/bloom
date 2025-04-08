//
//  OpenAISuggestGoalsResponse.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-03-03.
//

import Foundation
import BloomModel

struct OpenAISuggestGoalsResponse: Codable {
  let suggestedGoals: [SuggestedGoal]
  let suggestedReminders: [SuggestedReminder]
  let thoughtProcess: [ThoughtProcessStep]
}

struct ThoughtProcessStep: Codable {
  let step: String
}
