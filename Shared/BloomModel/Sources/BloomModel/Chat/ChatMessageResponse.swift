//
//  ChatMessageResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-12.
//

public struct ChatMessageResponse: Codable, Equatable, Sendable {
  public let messages: [String]

  public init(messages: [String]) {
    self.messages = messages
  }
}
