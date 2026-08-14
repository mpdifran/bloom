//
//  ChatTitleView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-12.
//

import SwiftUI
import SwiftData
import AppUI
import BloomUI
import DataContainer

struct ChatTitleView: View {
  let conversationID: String

  @Query private var conversations: [ChatConversation]

  @State private var presentedSheet: AnyView?

  init(conversationID: String) {
    self.conversationID = conversationID

    let predicate = #Predicate<ChatConversation> { conversation in
      conversation.id == conversationID
    }

    _conversations = Query(
      filter: predicate,
      animation: .default
    )
  }

  var body: some View {
    contentView
      .padding(.vertical, 6)
      .padding(.leading, 10)
      .padding(.trailing, 20)
      .glassEffect(.regular.interactive())
  }
}

private extension ChatTitleView {

  var conversation: ChatConversation? {
    conversations.first
  }

  var title: String {
    conversation?.name ?? String(localized: "New Chat", comment: "Title for chat title view")
  }

  var contentView: some View {
    HStack(spacing: 6) {
      BudImage(.budCoach, dimension: 40)
        .layoutPriority(10)

      Text(title)
        .fontDesign(.rounded)
        .bold()
        .contentTransition(.numericText())
        .lineLimit(2)
        .multilineTextAlignment(.leading)
        .minimumScaleFactor(0.8)
    }
    .onTapGesture {
      if let conversation {
        presentedSheet = RenameConversationView(conversation: conversation).asAny
      }
    }
    .animation(.bouncy, value: title)
    .sheet($presentedSheet)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      Text("Chat Content")
        .toolbar {
          ToolbarItem(placement: .principal) {
            ChatTitleView(conversationID: String.legacyConversationID)
          }
        }
    }
  }
}
