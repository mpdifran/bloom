//
//  ChatView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import SwiftData
import DataContainer

struct ChatView: View {

  @State private var viewModel = ChatViewModel()
  @State private var presentedSheet: AnyView?

  @Environment(\.dismiss) private var dismiss
  @Environment(TabController.self) private var tabController: TabController

  @Query(sort: \ChatMessage.date)
  private var chatMessages: [ChatMessage]

  var body: some View {
    ScrollViewReader { scrollViewProxy in
      ScrollView {
        LazyVStack {
          Group {
            if viewModel.assistantIsTyping {
              TypingIndicatorCell(isDirect: false)
                .id("typing-indicator")
                .transition(.blurReplace)

              statusTextView
            }

            ForEach(chatMessages.reversed()) { chatMessage in
              chatCell(for: chatMessage)
            }
          }
          .flippedUpsideDown()
        }
        .horizontallyCentered()
        .padding(.vertical)
      }
      .flippedUpsideDown()
    }
    .safeAreaPadding(.bottom, tabController.chatLauncherSafeAreaInset)
    .sheet($presentedSheet)
    .alert(error: $viewModel.error)
    .animation(.bouncy, value: chatMessages)
    .animation(.bouncy, value: viewModel.assistantTypingStatus)
    .topSafeAreaBlur()
  }
}

private extension ChatView {
  @ViewBuilder
  func chatCell(for chatMessage: ChatMessage) -> some View {
    switch chatMessage.content {
    case .message(let message):
      ChatBubbleCell(
        message: message,
        isDirect: false,
        isCurrentUser: chatMessage.isCurrentUser,
        showTail: true
      )
      .id(chatMessage.id)
      .transition(.blurReplace)
      .contextMenu {
        if chatMessage.isCurrentUser {
          Button("Resend", systemSymbol: .arrowUturnBackward) {
            Task {
              await viewModel.sendMessage(message, image: nil)
            }
          }
        }
      }
    case .imageData(let imageData):
      if let image = UIImage(data: imageData) {
        ChatImageCell(
          image: image,
          isCurrentUser: chatMessage.isCurrentUser
        )
        .id(chatMessage.id)
        .transition(.blurReplace)
      }
    case .richContent(let richContent):
      ChatRichContentWrapperCell(
        chatMessageID: chatMessage.id,
        data: richContent,
        hasPerformedAction: chatMessage.hasPerformedAction
      )
        .id(chatMessage.id)
        .transition(.blurReplace)
    @unknown default:
      EmptyView()
    }
  }

  @ViewBuilder
  var statusTextView: some View {
    if let status = viewModel.assistantTypingStatus {
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
  }
}

#Preview {
  PreviewEnvironment {
    ChatView()
  }
}
