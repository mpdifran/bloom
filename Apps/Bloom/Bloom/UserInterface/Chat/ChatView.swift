//
//  ChatView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import SwiftUI

struct ChatView: View {

  @State private var text: String = ""
  @State private var viewModel = ChatViewModel.shared

  @Environment(\.dismiss) private var dismiss

  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          ForEach(viewModel.chatMessages) { chatMessage in
            ChatBubbleCell(
              message: chatMessage.message,
              isDirect: false,
              isCurrentUser: chatMessage.isCurrentUser,
              showTail: true
            )
          }
        }
        .padding(.vertical)
      }
      .tint(.mutedIndigo)
      .safeAreaInset(edge: .bottom) {
        ChatBar(text: $text) {
          Task {
            await viewModel.sendMessage(text)
            text = ""
          }
        }
        .focused($isFocused)
        .padding(.horizontal)
      }
      .navigationTitle("Chat")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
          .bold()
        }
      }
    }
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

#Preview {
  ChatView()
}
