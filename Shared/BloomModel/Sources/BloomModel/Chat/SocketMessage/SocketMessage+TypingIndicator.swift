//
//  SocketMessage+TypingIndicator.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Foundation

public extension SocketMessage {
  struct TypingIndicator: Codable, Equatable, Sendable {
    public let isTyping: Bool
    public let conversationID: String?

    public init(isTyping: Bool, conversationID: String? = nil) {
      self.isTyping = isTyping
      self.conversationID = conversationID
    }
  }
}
