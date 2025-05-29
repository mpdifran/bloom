//
//  ChatCell.swift
//  Bloom
//
//  Created by Assistant on 2025-01-29.
//

import SwiftUI
import DataContainer
import UIKit

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
  func createMessageView(_ chatMessage: ChatMessageDTO) -> some View {
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
    case .richContent(let data):
      ChatRichContentWrapperCell(
        chatMessageID: chatMessage.id,
        data: data,
        hasPerformedAction: chatMessage.hasPerformedAction,
        dbID: chatMessage.dbID
      )
    case .invalid:
      ChatUnknownContentCell()
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

  @ViewBuilder
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
