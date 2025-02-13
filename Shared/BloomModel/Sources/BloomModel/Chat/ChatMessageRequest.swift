//
//  ChatMessageRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-12.
//

public struct ChatMessageRequest: Codable, Equatable, Sendable {
  public let message: String?
  public let healthData: ChatHealthData?

  public init(
    message: String?,
    healthData: ChatHealthData?
  ) {
    self.message = message
    self.healthData = healthData
  }
}
