//
//  ChatCellBuilder.swift
//  Bloom
//
//  Created by Zach Radford on 2025-05-24.
//

import DataContainer
import Foundation
import SwiftUI
import UIKit

enum ChatCellType: Equatable {
  case message(ChatMessage)
  case inProgress(ChatController.InProgressMessage)
  case typingIndicator
  case statusText(String)
  case prompts
}

struct ChatCellModel: Identifiable, Equatable {
  let id: String
  let contentType: ChatCellType
}

@Observable
final class ChatCellBuilder {
  private(set) var models: [ChatCellModel] = []
  private var existingMessageIds: Set<String> = []
  private var cachedMessageModels: [String: ChatCellModel] = [:]
  private var lastStatusText: String?
  private var lastTypingState: Bool = false
  
  func build(
    messages: [ChatMessage],
    inProgressMessages: [ChatController.InProgressMessage],
    statusText: String?,
    assistantIsTyping: Bool
  ) {
    // Handle empty state
    if messages.isEmpty && inProgressMessages.isEmpty && !assistantIsTyping {
      let promptsModel = ChatCellModel(
        id: "prompts",
        contentType: .prompts
      )
      
      // Only update if actually different
      if self.models.count != 1 || self.models.first != promptsModel {
        self.models = [promptsModel]
        self.existingMessageIds.removeAll()
        self.cachedMessageModels.removeAll()
      }
      return
    }
    
    // Start building new models array
    var newModels: [ChatCellModel] = []
    newModels.reserveCapacity(messages.count + inProgressMessages.count + 2)
    
    // Track which cached models are still valid
    var usedCacheIds = Set<String>()
    
    // Process regular messages (reverse since query returns newest first)
    let reversedMessages = messages.reversed()
    for message in reversedMessages {
      // Check if we have a cached model for this message
      if let cachedModel = cachedMessageModels[message.id] {
        newModels.append(cachedModel)
        usedCacheIds.insert(message.id)
      } else {
        // Create new model and cache it
        let messageModel = ChatCellModel(
          id: message.id,
          contentType: .message(message)
        )
        newModels.append(messageModel)
        cachedMessageModels[message.id] = messageModel
        usedCacheIds.insert(message.id)
      }
    }
    
    // Update message ID set
    self.existingMessageIds = Set(messages.map { $0.id })
    
    // Process in-progress messages - always create fresh models since they update frequently
    for inProgressMessage in inProgressMessages {
      if !existingMessageIds.contains(inProgressMessage.id) {
        // Always create new model for in-progress messages (no caching)
        let inProgressModel = ChatCellModel(
          id: inProgressMessage.id,
          contentType: .inProgress(inProgressMessage)
        )
        newModels.append(inProgressModel)
        // Don't cache in-progress messages since they're constantly updating
      }
    }
    
    // Handle status text - only update if changed
    if let statusText = statusText, statusText != lastStatusText {
      let statusModel = ChatCellModel(
        id: "status-text",
        contentType: .statusText(statusText)
      )
      newModels.append(statusModel)
      lastStatusText = statusText
    } else if statusText == nil && lastStatusText != nil {
      lastStatusText = nil
    } else if statusText == lastStatusText {
      // Reuse existing status model if text hasn't changed
      if let existingStatusModel = models.first(where: { $0.id == "status-text" }) {
        newModels.append(existingStatusModel)
      }
    }
    
    // Handle typing indicator - only update if state changed
    let shouldShowTyping = inProgressMessages.isEmpty && assistantIsTyping
    if shouldShowTyping && !lastTypingState {
      let typingIndicatorModel = ChatCellModel(
        id: "typing-indicator",
        contentType: .typingIndicator
      )
      newModels.append(typingIndicatorModel)
      lastTypingState = true
    } else if shouldShowTyping && lastTypingState {
      // Reuse existing typing indicator
      if let existingTypingModel = models.first(where: { $0.id == "typing-indicator" }) {
        newModels.append(existingTypingModel)
      }
    } else {
      lastTypingState = false
    }
    
    // Clean up unused cache entries
    cachedMessageModels = cachedMessageModels.filter { usedCacheIds.contains($0.key) }
    
    // Only update if the models have actually changed
    if !modelsAreEqual(self.models, newModels) {
      self.models = newModels
    }
  }
  
  private func modelsAreEqual(_ lhs: [ChatCellModel], _ rhs: [ChatCellModel]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    return zip(lhs, rhs).allSatisfy { $0 == $1 }
  }
}

struct ChatCell: View {
  let model: ChatCellModel

  var body: some View {
    switch model.contentType {
    case .message(let chatMessage):
      createMessageView(chatMessage)
    case .inProgress(let inProgressMessage):
      createInProgressView(inProgressMessage)
    case .typingIndicator:
      typingIndicatorView
    case .statusText(let status):
      createStatusTextView(status)
    case .prompts:
      promptsView
    }
  }
}

private extension ChatCell {
  @ViewBuilder
  func createMessageView(_ chatMessage: ChatMessage) -> some View {
    switch chatMessage.content {
    case .message(let message):
      ChatBubbleCell(
        message: message,
        isDirect: false,
        isCurrentUser: chatMessage.isCurrentUser,
        showTail: true
      )
    case .imageData(let imageData):
      if let image = UIImage(data: imageData) {
        ChatImageCell(
          image: image,
          isCurrentUser: chatMessage.isCurrentUser
        )
      }
    case .richContent(let richContent):
      ChatRichContentWrapperCell(
        chatMessageID: chatMessage.id,
        data: richContent,
        hasPerformedAction: chatMessage.hasPerformedAction,
        dbID: chatMessage.dbID
      )
    @unknown default:
      EmptyView()
    }
  }

  @ViewBuilder
  func createInProgressView(_ inProgressMessage: ChatController.InProgressMessage) -> some View {
    if let data = inProgressMessage.data {
      ChatRichContentWrapperCell(
        chatMessageID: "",
        data: data,
        hasPerformedAction: false,
        dbID: nil
      )
    } else {
      ChatBubbleCell(
        message: inProgressMessage.message,
        isDirect: false,
        isCurrentUser: false,
        showTail: true
      )
      .contentTransition(.opacity)
    }
  }

  var typingIndicatorView: some View {
    TypingIndicatorCell(
      isDirect: false
    )
  }

  func createStatusTextView(_ status: String) -> some View {
    HStack {
      Text(status)
        .font(.subheadline)
        .bold()
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
        .multilineTextAlignment(.leading)
        .lineLimit(2)
        .contentTransition(.numericText())

      Spacer(minLength: 60)
    }
    .padding(.horizontal)
  }

  var promptsView: some View {
    ChatPromptsView()
  }
}
