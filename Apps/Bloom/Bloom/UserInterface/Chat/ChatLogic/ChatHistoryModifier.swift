import Foundation
import SwiftData
import DataContainer
import BloomFoundation
import UIKit

actor ChatHistoryModifier {
  static let shared = ChatHistoryModifier()
  
  @AsyncStreamable private(set) var cellModels: [ChatCellModel] = []
  
  private let modelActor: ChatMessageModelActor
  private var messages: [ChatMessageDTO] = []
  private var inProgressMessages: [ChatController.InProgressMessage] = []
  private var assistantTypingStatus: String?
  private var assistantIsTyping = false
  
  private static let defaultMessageLimit = 20
  
  private init() {
    self.modelActor = ChatMessageModelActor.standard()
    
    // Load initial messages with default limit
    Task {
      await loadMessages()
    }
    
    // Subscribe to ChatController updates
    Task {
      await subscribeToUpdates()
    }
  }
  
  private func loadMessages(limit: Int? = defaultMessageLimit) async {
    do {
      let fetchedMessages = try await modelActor.fetchMessages(limit: limit)
      // Reverse the messages so they're in chronological order (oldest first)
      self.messages = fetchedMessages.reversed()
      buildCellModels()
    } catch {
      print("Failed to load chat messages: \(error)")
    }
  }
  
  private func subscribeToUpdates() async {
    // Subscribe to in-progress messages
    Task {
      for await messages in await ChatController.shared.$inProgressMessages {
        self.inProgressMessages = messages
        buildCellModels()
      }
    }
    
    // Subscribe to typing status
    Task {
      for await status in await ChatController.shared.$assistantTypingStatus {
        self.assistantTypingStatus = status
        buildCellModels()
      }
    }
    
    // Subscribe to typing indicator
    Task {
      for await isTyping in await ChatController.shared.$assistantIsTyping {
        self.assistantIsTyping = isTyping
        buildCellModels()
      }
    }
  }
  
  private func buildCellModels() {
    var models: [ChatCellModel] = []
    
    // Handle empty state
    if messages.isEmpty && inProgressMessages.isEmpty && !assistantIsTyping {
      models = [ChatCellModel(id: "prompts", contentType: .prompts)]
      self.cellModels = models
      return
    }
    
    // Add regular messages
    for message in messages {
      models.append(ChatCellModel(
        id: message.id,
        contentType: .message(message)
      ))
    }
    
    // Add in-progress messages
    for inProgressMessage in inProgressMessages {
      // Skip if already exists as a regular message
      if !messages.contains(where: { $0.id == inProgressMessage.id }) {
        models.append(ChatCellModel(
          id: inProgressMessage.id,
          contentType: .inProgress(inProgressMessage)
        ))
      }
    }
    
    // Add status text if present
    if let statusText = assistantTypingStatus {
      models.append(ChatCellModel(
        id: "status-text",
        contentType: .statusText(statusText)
      ))
    }
    
    // Add typing indicator
    if assistantIsTyping && assistantTypingStatus == nil {
      models.append(ChatCellModel(
        id: "typing-indicator",
        contentType: .typingIndicator
      ))
    }
    
    self.cellModels = models
  }
  
  func addMessage(_ chatMessage: ChatMessage) async throws {
    // Convert to DTO
    let dto = chatMessage.asDTO()
    
    // Add to end of list (newest messages at the end)
    var updatedMessages = messages
    updatedMessages.append(dto)
    
    // Trim from the beginning if we exceed the limit
    if updatedMessages.count > Self.defaultMessageLimit {
      updatedMessages = Array(updatedMessages.suffix(Self.defaultMessageLimit))
    }
    
    self.messages = updatedMessages
    buildCellModels()
    
    // Insert directly using model context
    let context = ModelContext(ContainerHolder.shared.container)
    context.insert(chatMessage)
    try context.save()
  }
  
  func updateMessageAction(id: String, hasPerformedAction: Bool) async throws {
    // Update in database and get the updated DTO
    guard let updatedDTO = try await modelActor.updateMessageAction(id: id, hasPerformedAction: hasPerformedAction) else {
      return
    }
    
    // Update in-memory list
    var updatedMessages = messages
    if let index = updatedMessages.firstIndex(where: { $0.id == id }) {
      updatedMessages[index] = updatedDTO
      self.messages = updatedMessages
      buildCellModels()
    }
  }
  
  func deleteAllMessages() async throws {
    // Clear in-memory list
    self.messages = []
    buildCellModels()
    
    // Delete from database
    let context = ModelContext(ContainerHolder.shared.container)
    try context.delete(model: ChatMessage.self)
    try context.save()
  }
  
  func refreshMessages() async {
    await loadMessages()
  }
  
  func loadMoreMessages() async {
    // Load all messages without limit to get more history
    await loadMessages(limit: nil)
  }
}

enum ChatMessageError: LocalizedError {
  case invalidMessage
  
  var errorDescription: String? {
    switch self {
    case .invalidMessage:
      return "Invalid chat message"
    }
  }
}