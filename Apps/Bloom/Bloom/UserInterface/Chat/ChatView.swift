//
//  ChatView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import SFSafeSymbols
import SwiftUI
import AppUI

struct ChatView: View {

  @State private var viewModel = ChatViewModel()
  @State private var presentedSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      ScrollViewReader { scrollViewProxy in
        ScrollView {
          VStack {
            ForEach(viewModel.chatMessages) { chatMessage in
              chatCell(for: chatMessage)
            }

            if viewModel.assistantIsTyping {
              statusTextView

              TypingIndicatorCell(isDirect: false)
                .id("typing-indicator")
                .transition(.blurReplace)
            }
          }
          .horizontallyCentered()
          .padding(.vertical)
        }
        .safeAreaInset(edge: .bottom) {
          ChatBar { (text, image) in
            Task {
              await viewModel.sendMessage(text, image: image)
            }
          }
          .focused($isFocused)
        }
        .navigationTitle("Chat")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Done") {
              dismiss()
            }
            .bold()
          }
          ToolbarItem(placement: .primaryAction) {
            Button {
              presentedSheet = ChatSettingsView().asAny
            } label: {
              Image(systemSymbol: .gear)
                .bold()
            }
          }
        }
        .onChange(of: viewModel.chatMessages) { _, messages in
          if let lastMessage = messages.last {
            withAnimation {
              scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
          }
        }
        .onChange(of: viewModel.assistantTypingStatus) { _, _ in
          guard viewModel.assistantIsTyping else { return }
          withAnimation {
            scrollViewProxy.scrollTo("typing-indicator", anchor: .bottom)
          }
        }
        .onChange(of: viewModel.assistantIsTyping) { _, assistantIsTyping in
          guard assistantIsTyping else { return }
          withAnimation {
            scrollViewProxy.scrollTo("typing-indicator", anchor: .bottom)
          }
        }
      }
      .groupedBackground()
      .sheet($presentedSheet)
      .alert(error: $viewModel.error)
      .animation(.bouncy, value: viewModel.chatMessages)
      .animation(.bouncy, value: viewModel.assistantTypingStatus)
    }
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

private extension ChatView {

  @ViewBuilder
  func chatCell(for chatMessage: ChatMessage) -> some View {
    switch chatMessage.content {
    case .text(let message):
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
    case .image(let image):
      ChatImageCell(
        image: image,
        isCurrentUser: chatMessage.isCurrentUser
      )
      .id(chatMessage.id)
      .transition(.blurReplace)
    case .goals(let goals):
      ChatGoalsCell(
        goals: goals
      )
      .id(chatMessage.id)
      .transition(.blurReplace)
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
