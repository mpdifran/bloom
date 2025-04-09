//
//  SocketMessage+Messages.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-01.
//

public extension SocketMessage {
  struct MessageRequest: Codable, Equatable, Sendable {
    public let text: String
    public let image: ImageFile?
    public let userInfo: String

    public init(
      text: String,
      image: ImageFile?,
      userInfo: String
    ) {
      self.text = text
      self.image = image
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
