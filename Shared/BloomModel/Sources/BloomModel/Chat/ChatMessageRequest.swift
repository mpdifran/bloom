//
//  ChatMessageRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-12.
//

import Foundation

public struct ChatMessageRequest: Codable, Equatable, Sendable {
  public let message: String
  public let healthData: String?

  public init(
    message: String,
    healthData: String?
  ) {
    self.message = message
    self.healthData = healthData
  }
}
