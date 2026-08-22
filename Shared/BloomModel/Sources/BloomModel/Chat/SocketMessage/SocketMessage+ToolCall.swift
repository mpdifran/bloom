//
//  SocketMessage+ToolCall.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-27.
//

import Foundation

public extension SocketMessage {
  struct ToolCallsRequest: Codable, Equatable, Sendable {
    public let runID: String
    public let toolCalls: [ToolCallWrapper]
    public let requestID: String?
    public let conversationID: String?
    public let lastMessageID: String?

    public init(runID: String, toolCalls: [ToolCallWrapper], requestID: String? = nil, conversationID: String? = nil, lastMessageID: String? = nil) {
      self.runID = runID
      self.toolCalls = toolCalls
      self.requestID = requestID
      self.conversationID = conversationID
      self.lastMessageID = lastMessageID
    }
  }
}

public extension SocketMessage {
  struct ToolCallWrapper: Codable, Equatable, Sendable {
    public let toolCallID: String
    public let kind: Kind

    public init(toolCallID: String, kind: Kind) {
      self.toolCallID = toolCallID
      self.kind = kind
    }
  }
}

public extension SocketMessage.ToolCallWrapper {
  enum Kind: Codable, Equatable, Sendable {
    case queries([SocketMessage.Query])
  }
}

public extension SocketMessage {
  struct ToolCallsResponse: Codable, Equatable, Sendable {
    public let runID: String
    public let toolCallResults: [ToolCallResult]
    public let requestID: String?
    public let conversationID: String?
    public let lastMessageID: String?

    /// BCP-47 tag for the language the client's UI is running in, e.g. "es-MX".
    ///
    /// Tool call results re-enter the same streaming path as a message, so the language has to
    /// travel with them too. Optional for the same backwards-compatibility reason.
    public let locale: String?

    /// BCP-47 tag for the language the app's interface is displayed in. See `MessageRequest`.
    public let interfaceLocale: String?

    /// See `MessageRequest.protocolVersion`.
    ///
    /// Carried here for the same reason as `locale`: a tool call result re-enters the streaming
    /// path, and without it the follow-up turn would forget what the client can render.
    public let protocolVersion: Int?

    public init(
      runID: String,
      toolCallResults: [ToolCallResult],
      requestID: String? = nil,
      conversationID: String? = nil,
      lastMessageID: String? = nil,
      locale: String? = nil,
      interfaceLocale: String? = nil,
      protocolVersion: Int? = nil
    ) {
      self.runID = runID
      self.toolCallResults = toolCallResults
      self.requestID = requestID
      self.conversationID = conversationID
      self.lastMessageID = lastMessageID
      self.locale = locale
      self.interfaceLocale = interfaceLocale
      self.protocolVersion = protocolVersion
    }
  }
}

public extension SocketMessage {
  struct ToolCallResult: Codable, Equatable, Sendable {
    public let toolCallID: String
    public let data: String

    public init(toolCallID: String, data: String = "") {
      self.toolCallID = toolCallID
      self.data = data
    }
  }
}
