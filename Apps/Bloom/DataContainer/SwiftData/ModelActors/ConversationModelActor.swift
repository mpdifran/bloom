//
//  ConversationModelActor.swift
//  DataContainer
//
//  Created by Assistant on 2025-09-30.
//

import SwiftData
import Foundation

@ModelActor
public actor ConversationModelActor {

  // MARK: - Conversation Management

  public func createConversation(name: String) throws -> ChatConversationDTO {
    let conversation = ChatConversation(name: name)
    modelContext.insert(conversation)
    try modelContext.save()
    return conversation.asDTO()
  }

  public func fetchAllConversations() throws -> [ChatConversationDTO] {
    let descriptor = FetchDescriptor<ChatConversation>(
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
    return try modelContext.fetch(descriptor).map { $0.asDTO() }
  }

  public func fetchConversation(by id: String) throws -> ChatConversationDTO? {
    let predicate = #Predicate<ChatConversation> { conversation in
      conversation.id == id
    }
    let descriptor = FetchDescriptor<ChatConversation>(predicate: predicate)
    return try modelContext.fetch(descriptor).first?.asDTO()
  }

  public func updateConversationName(conversationID: String, name: String) throws -> ChatConversationDTO? {
    let predicate = #Predicate<ChatConversation> { conversation in
      conversation.id == conversationID
    }
    let descriptor = FetchDescriptor<ChatConversation>(predicate: predicate)
    guard let conversation = try modelContext.fetch(descriptor).first else { return nil }

    conversation.name = name
    try modelContext.save()
    return conversation.asDTO()
  }

  public func updateConversationLastMessageID(conversationID: String, lastMessageID: String?) throws -> ChatConversationDTO? {
    let predicate = #Predicate<ChatConversation> { conversation in
      conversation.id == conversationID
    }
    let descriptor = FetchDescriptor<ChatConversation>(predicate: predicate)
    guard let conversation = try modelContext.fetch(descriptor).first else { return nil }

    conversation.lastMessageID = lastMessageID
    try modelContext.save()
    return conversation.asDTO()
  }

  public func deleteConversation(conversationID: String) throws {
    let predicate = #Predicate<ChatConversation> { conversation in
      conversation.id == conversationID
    }
    let descriptor = FetchDescriptor<ChatConversation>(predicate: predicate)
    guard let conversation = try modelContext.fetch(descriptor).first else { return }

    // This will cascade delete all associated messages
    modelContext.delete(conversation)
    try modelContext.save()
  }

  // MARK: - Message Management

  public func addMessageToConversation(
    conversationID: String,
    id: String = UUID().uuidString,
    isCurrentUser: Bool,
    date: Date = .now,
    message: String,
    dbID: String? = nil,
    hasPerformedAction: Bool = false,
    responseID: String? = nil,
    requestID: String? = nil
  ) throws -> ChatMessageDTO? {
    let predicate = #Predicate<ChatConversation> { conversation in
      conversation.id == conversationID
    }
    let descriptor = FetchDescriptor<ChatConversation>(predicate: predicate)
    guard let conversation = try modelContext.fetch(descriptor).first else { return nil }

    let chatMessage = ChatMessage(
      id: id,
      isCurrentUser: isCurrentUser,
      date: date,
      message: message,
      dbID: dbID,
      hasPerformedAction: hasPerformedAction,
      responseID: responseID,
      requestID: requestID,
      conversation: conversation
    )

    conversation.updatedAt = .now
    modelContext.insert(chatMessage)
    try modelContext.save()
    return chatMessage.asDTO()
  }

  public func addRichContentMessageToConversation(
    conversationID: String,
    id: String = UUID().uuidString,
    isCurrentUser: Bool,
    date: Date = .now,
    richContent: Data,
    dbID: String? = nil,
    hasPerformedAction: Bool = false,
    responseID: String? = nil,
    requestID: String? = nil
  ) throws -> ChatMessageDTO? {
    let predicate = #Predicate<ChatConversation> { conversation in
      conversation.id == conversationID
    }
    let descriptor = FetchDescriptor<ChatConversation>(predicate: predicate)
    guard let conversation = try modelContext.fetch(descriptor).first else { return nil }

    let chatMessage = ChatMessage(
      id: id,
      isCurrentUser: isCurrentUser,
      date: date,
      richContent: richContent,
      dbID: dbID,
      hasPerformedAction: hasPerformedAction,
      responseID: responseID,
      requestID: requestID,
      conversation: conversation
    )

    conversation.updatedAt = .now
    modelContext.insert(chatMessage)
    try modelContext.save()
    return chatMessage.asDTO()
  }

  public func addImageMessageToConversation(
    conversationID: String,
    id: String = UUID().uuidString,
    isCurrentUser: Bool,
    date: Date = .now,
    imageData: Data,
    dbID: String? = nil,
    hasPerformedAction: Bool = false,
    responseID: String? = nil,
    requestID: String? = nil
  ) throws -> ChatMessageDTO? {
    let predicate = #Predicate<ChatConversation> { conversation in
      conversation.id == conversationID
    }
    let descriptor = FetchDescriptor<ChatConversation>(predicate: predicate)
    guard let conversation = try modelContext.fetch(descriptor).first else { return nil }

    let chatMessage = ChatMessage(
      id: id,
      isCurrentUser: isCurrentUser,
      date: date,
      imageData: imageData,
      dbID: dbID,
      hasPerformedAction: hasPerformedAction,
      responseID: responseID,
      requestID: requestID,
      conversation: conversation
    )

    conversation.updatedAt = .now
    modelContext.insert(chatMessage)
    try modelContext.save()
    return chatMessage.asDTO()
  }

  public func fetchMessagesForConversation(conversationID: String) throws -> [ChatMessageDTO] {
    let predicate = #Predicate<ChatMessage> { message in
      message.conversation?.id == conversationID
    }
    let descriptor = FetchDescriptor<ChatMessage>(
      predicate: predicate,
      sortBy: [SortDescriptor(\ChatMessage.date, order: .forward)]
    )
    return try modelContext.fetch(descriptor).map { $0.asDTO() }
  }

  public func deleteMessage(messageID: String) throws {
    let predicate = #Predicate<ChatMessage> { message in
      message.id == messageID
    }
    let descriptor = FetchDescriptor<ChatMessage>(predicate: predicate)
    guard let message = try modelContext.fetch(descriptor).first else { return }

    modelContext.delete(message)
    try modelContext.save()
  }

  // MARK: - Conversation State Management

  public func fixUnassignedMessages() throws {
    // Capture the constant for use in predicates
    let legacyID = String.legacyConversationID

    // Fetch or create the legacy conversation
    let predicate = #Predicate<ChatConversation> { conversation in
      conversation.id == legacyID
    }
    let descriptor = FetchDescriptor<ChatConversation>(predicate: predicate)

    let legacyConversation: ChatConversation
    if let existing = try modelContext.fetch(descriptor).first {
      legacyConversation = existing
    } else {
      // Create with hard-coded ID
      let conversation = ChatConversation(
        id: .legacyConversationID,
        name: "Legacy Chat",
        createdDate: Date.distantPast
      )
      modelContext.insert(conversation)
      legacyConversation = conversation
    }

    // Find all messages without a conversation OR with a different conversation
    let allMessagesPredicate = #Predicate<ChatMessage> { message in
      message.conversation == nil || message.conversation?.id != legacyID
    }
    let allMessagesDescriptor = FetchDescriptor<ChatMessage>(predicate: allMessagesPredicate)
    let messagesToFix = try modelContext.fetch(allMessagesDescriptor)

    // Assign them to the legacy conversation
    for message in messagesToFix {
      message.conversation = legacyConversation
    }

    try modelContext.save()
  }

  public func getOrCreateLegacyConversation() throws -> ChatConversationDTO {
    // Try to fetch by hard-coded ID
    if let existing = try fetchConversation(by: String.legacyConversationID) {
      return existing
    }

    // Create with hard-coded ID
    let conversation = ChatConversation(
      id: String.legacyConversationID,
      name: "Legacy Chat",
      createdDate: Date.distantPast
    )
    modelContext.insert(conversation)
    try modelContext.save()
    return conversation.asDTO()
  }
}
