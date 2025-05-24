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

  func build(
    messages: [ChatMessage],
    inProgressMessages: [ChatController.InProgressMessage],
    statusText: String?,
    assistantIsTyping: Bool
  ) {
    var models: [ChatCellModel] = []

    if messages.isEmpty && inProgressMessages.isEmpty && !assistantIsTyping {
      let promptsModel = ChatCellModel(
        id: "prompts",
        contentType: .prompts
      )
      models.append(promptsModel)
      self.models = models
      // Prompts is the empty state. Return early.
      return
    }

    for message in messages {
      let messageModel = ChatCellModel(
        id: message.id,
        contentType: .message(message)
      )
      models.append(messageModel)
    }

    for inProgressMessage in inProgressMessages {
      let inProgressModel = ChatCellModel(
        id: inProgressMessage.id,
        contentType: .inProgress(inProgressMessage)
      )
      models.append(inProgressModel)
    }
    
    if let statusText = statusText {
      let statusModel = ChatCellModel(
        id: statusText,
        contentType: .statusText(statusText)
      )
      models.append(statusModel)
    }

    if inProgressMessages.isEmpty && assistantIsTyping {
      let typingIndicatorModel = ChatCellModel(
        id: "typing-indicator",
        contentType: .typingIndicator
      )
      models.append(typingIndicatorModel)
    }


    self.models = models
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
