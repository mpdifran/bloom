//
//  ChatConversationView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-08.
//

import SwiftUI
import SwiftData
import DataContainer

struct ChatConversationView: View {
  @Query(sort: \ChatConversation.updatedAt, order: .reverse) private var conversations: [ChatConversation]

  var body: some View {
    BloomScrollView {
      ForEach(conversations) { conversation in
        NavigationLink(value: conversation) {
          ConversationCell(conversation: conversation)
        }
        .buttonStyle(.plain)
      }
    }
    .navigationTitle("Conversations")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ChatConversationView()
    }
  }
}
