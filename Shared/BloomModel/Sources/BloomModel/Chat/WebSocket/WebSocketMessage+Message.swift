//
//  WebSocketMessage+Message.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-01.
//

public extension WebSocketMessage {
  struct Message: Codable, Equatable, Sendable {
    public let text: String

    public init(text: String) {
      self.text = text
    }
  }
}
