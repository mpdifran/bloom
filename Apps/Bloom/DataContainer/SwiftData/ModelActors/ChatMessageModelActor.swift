//
//  ChatMessageModelActor.swift
//  DataContainer
//
//  Created by Assistant on 2025-01-29.
//

import Foundation
import SwiftData

@ModelActor
public final actor ChatMessageModelActor: SharedModelActor {

  private var context: ModelContext { modelExecutor.modelContext }
}

public extension ChatMessageModelActor {

  func fetchMessages(limit: Int? = nil, conversationID: String? = nil) throws -> [ChatMessageDTO] {
    var descriptor: FetchDescriptor<ChatMessage>

    if let conversationID {
      // Filter by conversation
      let predicate = #Predicate<ChatMessage> { message in
        message.conversation?.id == conversationID
      }
      descriptor = FetchDescriptor<ChatMessage>(
        predicate: predicate,
        sortBy: [SortDescriptor(\.date, order: .reverse)]
      )
    } else {
      // No filter - get all messages
      descriptor = FetchDescriptor<ChatMessage>(
        sortBy: [SortDescriptor(\.date, order: .reverse)]
      )
    }

    if let limit {
      descriptor.fetchLimit = limit
    }

    return try context.fetch(descriptor).map { $0.asDTO() }
  }

  func fetchMessage(by id: String) throws -> ChatMessageDTO? {
    let predicate = #Predicate<ChatMessage> { message in
      message.id == id
    }
    let descriptor = FetchDescriptor<ChatMessage>(predicate: predicate)
    guard let message = try context.fetch(descriptor).first else { return nil }
    return message.asDTO()
  }
  
  func updateMessageAction(id: String, hasPerformedAction: Bool) throws -> ChatMessageDTO? {
    let predicate = #Predicate<ChatMessage> { message in
      message.id == id
    }
    
    let descriptor = FetchDescriptor<ChatMessage>(predicate: predicate)
    guard let chatMessage = try context.fetch(descriptor).first else { return nil }
    
    chatMessage.hasPerformedAction = hasPerformedAction
    try context.save()
    
    return chatMessage.asDTO()
  }
}
