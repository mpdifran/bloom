//
//  SuggestGoalsRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation

public struct SuggestGoalsRequest: Codable, Equatable, Sendable {
  public let healthData: String
  public let currentGoals: String
  public let isConversation: Bool

  public init(
    healthData: String,
    currentGoals: String,
    isConversation: Bool
  ) {
    self.healthData = healthData
    self.currentGoals = currentGoals
    self.isConversation = isConversation
  }
}
