//
//  SocketMessage+Messages.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-01.
//

public extension SocketMessage {
  struct MessageRequest: Codable, Equatable, Sendable {
    public let text: String
    public let imageFileIDs: [String]
    public let userInfo: String

    public init(
      text: String,
      imageFileIDs: [String],
      userInfo: String
    ) {
      self.text = text
      self.imageFileIDs = imageFileIDs
      self.userInfo = userInfo
    }
  }

  struct MessageChunkResponse: Codable, Equatable, Sendable {
    public let id: String
    public let chunk: String

    public init(
      id: String,
      chunk: String
    ) {
      self.id = id
      self.chunk = chunk
    }
  }

  struct MessageResponse: Codable, Equatable, Sendable {
    public let id: String
    public let message: String

    public init(
      id: String,
      message: String
    ) {
      self.id = id
      self.message = message
    }
  }
}
