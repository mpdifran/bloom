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
import BloomUI

struct ChatConversationView: View {
  let tabController: TabController
  let themeController: ThemeController
  let onSelectConversation: (ChatConversation, Bool) -> Void

  @Query(
    filter: #Predicate<ChatConversation> { $0.isPinned == true },
    sort: \ChatConversation.updatedAt,
    order: .reverse
  ) private var pinnedConversations: [ChatConversation]

  @Query(
    filter: #Predicate<ChatConversation> { $0.isPinned == false },
    sort: \ChatConversation.updatedAt,
    order: .reverse
  ) private var unpinnedConversations: [ChatConversation]

  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var error: Error?
  @State private var presentedSheet: AnyView?

  var body: some View {
    BloomScrollView {
      if pinnedConversations.isEmpty && unpinnedConversations.isEmpty {
        noContentView
      } else {
        if pinnedConversations.isNotEmpty {
          SectionTitleView("Pinned")
            .padding(.horizontal)

          ForEach(pinnedConversations) { conversation in
            conversationCell(conversation)
          }
        }

        if pinnedConversations.isNotEmpty && unpinnedConversations.isNotEmpty {
          SectionTitleView("Conversations")
            .padding(.horizontal)
        }
        ForEach(unpinnedConversations) { conversation in
          conversationCell(conversation)
        }
      }
    }
    .navigationTitle("Conversations")
    .alert(error: $error)
    .sheet($presentedSheet)
    .animation(.default, value: pinnedConversations)
    .animation(.default, value: unpinnedConversations)
  }
}

private extension ChatConversationView {

  var noContentView: some View {
    ContentUnavailableView {
      VStack {
        Spacer()
        BudImage(.budYoga, dimension: 200)
        Text("No Conversations")
          .font(.title)
          .bold()
          .fontDesign(.rounded)
        Text("Tell me what's on your mind!")
          .font(.body)
          .foregroundStyle(.secondary)
        Spacer()
      }
    }
  }

  @ViewBuilder
  func conversationCell(_ conversation: ChatConversation) -> some View {
    ConversationCell(conversation: conversation)
      .confirmationDialog($confirmationDialogDetails)
      .onTapGesture {
        onSelectConversation(conversation, true)
      }
      .contextMenu {
        Button {
          presentedSheet = RenameConversationView(conversation: conversation).asAny
        } label: {
          Label("Rename", systemSymbol: .squareAndPencil)
        }

        Button {
          togglePin(for: conversation)
        } label: {
          Label(conversation.isPinned ? "Unpin" : "Pin", systemSymbol: .pin)
        }

        Divider()

        Button(role: .destructive) {
          showDeleteConfirmation(for: conversation)
        } label: {
          Label("Delete", systemSymbol: .trash)
            .tint(.red)
        }
      }
  }

  func showDeleteConfirmation(for conversation: ChatConversation) {
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

  func togglePin(for conversation: ChatConversation) {
    Task {
      do {
        let conversationActor = ConversationModelActor(modelContainer: ContainerHolder.shared.container)
        _ = try await conversationActor.toggleConversationPin(conversationID: conversation.id)
      } catch {
        self.error = error
      }
    }
  }

  func deleteConversation(_ conversation: ChatConversation) async {
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
