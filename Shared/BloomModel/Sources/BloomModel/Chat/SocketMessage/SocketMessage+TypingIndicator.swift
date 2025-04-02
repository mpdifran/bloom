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

    public init(isTyping: Bool) {
      self.isTyping = isTyping
    }
  }
}
