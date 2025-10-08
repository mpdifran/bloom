//
//  ConversationCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-08.
//

import SwiftUI
import DataContainer
import SFSafeSymbols

struct ConversationCell: View {
  let conversation: ChatConversation

  var body: some View {
    HStack {
      Group {
        Image(systemSymbol: .quoteBubble)
          .bold()

        VStack(alignment: .leading) {
          Text(conversation.name)
            .bold()

          if let userMessage = conversation.latestUserMessage?.message {
            Text(userMessage)
              .font(.body)
              .foregroundStyle(.secondary)
          }
        }
        .multilineTextAlignment(.leading)
      }
      .fontDesign(.rounded)
      .font(.body)

      Spacer(minLength: 0)

      ConversationRelativeTimeLabel(date: conversation.latestUserMessage?.date ?? .now)
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ConversationCell(
        conversation: ChatConversation(
          id: "convo_123",
          name: "Factors Affecting Sleep",
          lastMessageID: nil,
          createdDate: .now
        )
      )
      ConversationCell(
        conversation: ChatConversation(
          id: "convo_123",
          name: "What foods should I eat to build muscle?",
          lastMessageID: nil,
          createdDate: .now.addingTimeInterval(-102465)
        )
      )
    }
  }
}
