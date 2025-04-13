//
//  ModelContext+ChatMessage.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-13.
//

import SwiftData

public extension ModelContext {

  func fetchFirstChatMessage(id: String) throws -> ChatMessage? {
    let descriptor = FetchDescriptor<ChatMessage>(
      predicate: #Predicate<ChatMessage> { model in
        model.id == id
      }
    )
    return try fetch(descriptor).first
  }

  func markChatMessageActionTaken(id: String) throws {
    guard let chatMessage = try fetchFirstChatMessage(id: id) else { return }

    chatMessage.hasPerformedAction = true

    try save()
  }
}
