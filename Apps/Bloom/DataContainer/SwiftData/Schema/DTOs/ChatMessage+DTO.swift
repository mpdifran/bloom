//
//  ChatMessage+DTO.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-13.
//

import Foundation
import SwiftData

public extension ChatMessageDTO {
  enum Content: Sendable, Equatable {
    case message(String)
    case imageData(Data)
    case richContent(Data)
    case invalid
  }
}

public struct ChatMessageDTO: Sendable, Equatable, Identifiable {
  public let persistentID: PersistentIdentifier
  public let id: String
  public let isCurrentUser: Bool
  public let date: Date
  public let content: Content
  public let hasPerformedAction: Bool
  public let dbID: String?
  public let requestID: String?
  public let responseID: String?
}

public extension ChatMessage {

  func asDTO() -> ChatMessageDTO {
    let content: ChatMessageDTO.Content
    if let richContentData = richContent {
      content = .richContent(richContentData)
    } else if let imageData {
      content = .imageData(imageData)
    } else {
      content = .message(message ?? "")
    }
    return ChatMessageDTO(
      persistentID: persistentModelID,
      id: id,
      isCurrentUser: isCurrentUser,
      date: date,
      content: content,
      hasPerformedAction: hasPerformedAction,
      dbID: dbID,
      requestID: requestID,
      responseID: responseID
    )
  }
}
