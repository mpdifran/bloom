//
//  SocketMessage+ResponseCompleted.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-05-26.
//

import Foundation

public extension SocketMessage {
  struct ResponseCompleted: Codable, Equatable, Sendable {
    public var type: `Type`
    public let requestID: String?
    public let conversationID: String?
    public let lastMessageID: String?

    public enum `Type`: String, Codable, Equatable, Sendable {
      case responseCompleted
    }

    public init(requestID: String? = nil, conversationID: String? = nil, lastMessageID: String? = nil) {
      self.type = .responseCompleted
      self.requestID = requestID
      self.conversationID = conversationID
      self.lastMessageID = lastMessageID
    }
  }
}
