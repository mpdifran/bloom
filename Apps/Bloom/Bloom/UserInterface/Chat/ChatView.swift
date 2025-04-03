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

  @State private var text: String = ""
  @State private var viewModel = ChatViewModel.shared
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  @Environment(\.dismiss) private var dismiss

  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      ScrollViewReader { scrollViewProxy in
        ScrollView {
          VStack {
            ForEach(viewModel.chatMessages) { chatMessage in
              ChatBubbleCell(
                message: chatMessage.message,
                isDirect: false,
                isCurrentUser: chatMessage.isCurrentUser,
                showTail: true
              )
              .id(chatMessage.id)
              .transition(chatMessage.isCurrentUser ? .move(edge: .trailing) : .move(edge: .leading))
            }
          }
          .padding(.vertical)
        }
        .safeAreaInset(edge: .bottom) {
          ChatBar(text: $text) {
            let textToSend = text
            text = ""
            ThrowingUserTask(error: $error) {
              try await viewModel.sendMessage(textToSend)
            }
          }
          .focused($isFocused)
          .padding()
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
      .alert(error: $error)
      .animation(.bouncy, value: viewModel.chatMessages)
      .presentationCompactAdaptation(.fullScreenCover)
    }
  }
}

#Preview {
  PreviewEnvironment {
    ChatView()
  }
}
