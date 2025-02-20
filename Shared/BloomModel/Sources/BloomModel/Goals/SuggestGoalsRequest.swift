//
//  SuggestGoalsRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation

public struct SuggestGoalsRequest: Codable, Equatable, Sendable {
  public let healthData: String
  public let isConversation: Bool

  public init(
    healthData: String,
    isConversation: Bool
  ) {
    self.healthData = healthData
    self.isConversation = isConversation
  }
}
