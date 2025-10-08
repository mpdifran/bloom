//
//  SocketMessage+ConversationName.swift
//  bloom-model
//
//  Created by Assistant on 2025-10-08.
//

import Foundation

public extension SocketMessage {
  struct ConversationNameUpdate: Codable, Equatable, Sendable {
    public let conversationID: String
    public let name: String

    public init(conversationID: String, name: String) {
      self.conversationID = conversationID
      self.name = name
    }
  }
}
