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
              if let image = chatMessage.image {
                ChatImageCell(
                  image: image,
                  isCurrentUser: chatMessage.isCurrentUser
                )
              }
              ChatBubbleCell(
                message: chatMessage.message,
                isDirect: false,
                isCurrentUser: chatMessage.isCurrentUser,
                showTail: true
              )
              .id(chatMessage.id)
              .transition(chatMessage.isCurrentUser ? .move(edge: .trailing) : .move(edge: .leading))
            }

            if viewModel.assistantIsTyping {
              TypingIndicatorCell(isDirect: false)
                .transition(.move(edge: .leading))
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
      }
      .groupedBackground()
      .sheet($presentedSheet)
      .alert(error: $viewModel.error)
      .animation(.bouncy, value: viewModel.chatMessages)
    }
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

#Preview {
  PreviewEnvironment {
    ChatView()
  }
}
