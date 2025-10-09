//
//  ChatConversationView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-08.
//

import SwiftUI
import SwiftData
import DataContainer
import AppUI
import SFSafeSymbols

struct ChatConversationView: View {
  let tabController: TabController
  let themeController: ThemeController
  let onSelectConversation: (ChatConversation, Bool) -> Void

  @Query(sort: \ChatConversation.updatedAt, order: .reverse) private var conversations: [ChatConversation]
  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var error: Error?

  var body: some View {
    BloomScrollView {
      ForEach(conversations) { conversation in
        ConversationCell(conversation: conversation)
          .confirmationDialog($confirmationDialogDetails)
          .onTapGesture {
            onSelectConversation(conversation, true)
          }
          .contextMenu {
            Button(role: .destructive) {
              showDeleteConfirmation(for: conversation)
            } label: {
              Label("Delete", systemSymbol: .trash)
                .tint(.red)
            }
          }
      }
    }
    .navigationTitle("Conversations")
    .alert(error: $error)
    .animation(.default, value: conversations.count)
  }

  private func showDeleteConfirmation(for conversation: ChatConversation) {
    confirmationDialogDetails = ConfirmationDialogDetails(
      title: "Are You Sure?",
      message: "This conversation and all its messages will be deleted. This can't be undone.",
      buttons: [
        ConfirmationDialogDetails.Button(title: "Delete", role: .destructive) {
          Task {
            await deleteConversation(conversation)
          }
        },
        ConfirmationDialogDetails.Button(title: "Cancel", role: .cancel) {
          // Do nothing
        }
      ]
    )
  }

  private func deleteConversation(_ conversation: ChatConversation) async {
    do {
      let conversationActor = ConversationModelActor(modelContainer: ContainerHolder.shared.container)
      try await conversationActor.deleteConversation(conversationID: conversation.id)
    } catch {
      self.error = error
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ChatConversationView(
        tabController: TabController(),
        themeController: ThemeController.shared,
        onSelectConversation: { _, _ in }
      )
    }
  }
}
