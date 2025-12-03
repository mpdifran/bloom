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

  @FocusState private var isFocused

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  var body: some View {
    BloomScrollView {
      if !aiFeatureSettings.chatEnabled {
        featureDisabledView
      } else if pinnedConversations.isEmpty && unpinnedConversations.isEmpty {
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
    .navigationTitle("Chat with Bud")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          presentedSheet = ChatSettingsView().asAny
        } label: {
          Image(systemSymbol: .sliderHorizontal3)
            .bold()
        }
        .buttonStyle(.plain)
      }
    }
    .alert(error: $error)
    .sheet($presentedSheet)
    .animation(.default, value: pinnedConversations)
    .animation(.default, value: unpinnedConversations)
    .animation(.default, value: aiFeatureSettings.chatEnabled)
    .safeAreaInset(edge: .bottom) {
      if aiFeatureSettings.chatEnabled {
        NewConversationChatMessageBar(
          tabController: tabController,
          themeController: themeController,
          onSelectConversation: onSelectConversation
        )
        .focused($isFocused)
      }
    }
    .onAppear {
      guard pinnedConversations.isEmpty && unpinnedConversations.isEmpty else {
        return
      }

      isFocused = true
    }
  }
}

private extension ChatConversationView {

  var featureDisabledView: some View {
    VStack {
      Spacer()
      BudImage(.budThinking, dimension: 200)

      Text("Bud can’t help right now")
        .font(.title)
        .bold()
        .fontDesign(.rounded)
      Text("To chat with Bud about your health, you’ll need to turn Chat back on. You’re always in control of what data gets used.")
        .font(.body)
        .foregroundStyle(.secondary)

      PrivacyAIFeatureOptInCell(
        title: "Chat with Bud",
        subtitle: "Chat with Bud about your health and wellness.",
        isEnabled: $aiFeatureSettings.chatEnabled) {
          ChatWithBudIcon()
            .frame(width: 40)
        }
        .tint(.mutedLightBlue)
        .cardContainer()

      Spacer()
    }
    .multilineTextAlignment(.center)
    .horizontallyCentered()
  }

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
