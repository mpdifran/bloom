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

  struct MessagesResponse: Codable, Equatable, Sendable {
    public let texts: [String]

    public init(texts: [String]) {
      self.texts = texts
    }
  }
}
