//
//  ChatConversation+DTO.swift
//  DataContainer
//
//  Created by Assistant on 2025-10-06.
//

import Foundation
import SwiftData

public struct ChatConversationDTO: Sendable, Equatable, Identifiable {
  public let persistentID: PersistentIdentifier
  public let id: String
  public let name: String
  public let lastMessageID: String?
  public let createdDate: Date
}

public extension ChatConversation {

  func asDTO() -> ChatConversationDTO {
    ChatConversationDTO(
      persistentID: persistentModelID,
      id: id,
      name: name,
      lastMessageID: lastMessageID,
      createdDate: createdDate
    )
  }
}
