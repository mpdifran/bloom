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
  @State private var isAtBottom = false

  @Environment(\.dismiss) private var dismiss
  @Environment(TabController.self) private var tabController: TabController

  @Query(sort: \ChatMessage.date)
  private var chatMessages: [ChatMessage]

  var body: some View {
    ScrollViewReader { scrollViewProxy in
      /// The chat view uses a double-flip technique to achieve correct scrolling behaviour:
      /// 1. The content inside the ScrollView is flipped upside down so new messages appear at the bottom.
      /// 2. The entire ScrollView is then flipped upside down to correct the orientation.
      /// This creates the illusion of messages scrolling up from the bottom while maintaining proper layout.
      /// Views must be added in the opposite order they appear in a VStack since they are flipped.
      ZStack(alignment: .bottom) {
        ScrollView {
          LazyVStack {
            Group {
              // Dummy view to help the ScrollView know where its bottom is.
              bottomAnchorView

              if viewModel.assistantIsTyping {
                TypingIndicatorCell(isDirect: false)
                  .id("typing-indicator")
                  .transition(.blurReplace)

                statusTextView
              }

              // Messages must be in reverse order since the View is flipped.
              ForEach(chatMessages.reversed()) { chatMessage in
                chatCell(for: chatMessage)
              }
            }
            .flippedUpsideDown() // Flip the content.
          }
          .horizontallyCentered()
          .padding(.vertical)
        }
        .flippedUpsideDown() // Flip the ScrollView.

        if !isAtBottom {
          Button {
            withAnimation {
              scrollViewProxy.scrollTo("bottom-anchor", anchor: .top)
            }
          } label: {
            Image(systemSymbol: .arrowDown)
              .font(.body)
              .foregroundStyle(.text, .fill)
              .frame(square: 32)
              .background(Circle().fill(.ultraThinMaterial))
              .shadow(radius: 2)
          }
          .padding(.bottom, 8)
          .transition(.scale.combined(with: .opacity))
        }
      }
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

  var bottomAnchorView: some View {
    Color.clear
      .frame(height: 1)
      .id("bottom-anchor")
      .onAppear {
        withAnimation {
          isAtBottom = true
        }
      }
      .onDisappear {
        withAnimation {
          isAtBottom = false
        }
      }
  }
}

#Preview {
  PreviewEnvironment {
    ChatView()
  }
}
