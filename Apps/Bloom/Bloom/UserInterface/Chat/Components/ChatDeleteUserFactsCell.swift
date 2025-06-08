//
//  ChatDeleteUserFactsCell.swift
//  Bloom
//
//  Created by Claude on 2025-06-08.
//

import SwiftUI
import BloomModel
import DataContainer
import SFSafeSymbols

struct ChatDeleteUserFactsCell: View {
  let chatMessageID: String
  let deleteUserFacts: SocketMessage.DeleteUserFacts
  let hasPerformedAction: Bool
  
  var body: some View {
    ForEach(deleteUserFacts.facts, id: \.id) { deletedFact in
      HStack {
        Image(systemSymbol: .brainHeadProfileFill)
          .foregroundStyle(.tint)

        VStack(alignment: .leading) {
          Text("Memory Removed")
            .font(.caption)
            .foregroundStyle(.secondary)

          Text(deletedFact.fact)
            .font(.body)
            .bold()
            .fontDesign(.rounded)
            .foregroundColor(.primary)
            .strikethrough()
        }

        Spacer(minLength: 0)

        DisclosureIndicator()
      }
      .cardContainer()
      .tint(.mutedYellow)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ChatDeleteUserFactsCell(
        chatMessageID: "test",
        deleteUserFacts: SocketMessage.DeleteUserFacts(
          facts: [
            SocketMessage.DeleteUserFacts.DeletedFact(
              id: "fact1",
              fact: "User has a knee injury from running"
            ),
            SocketMessage.DeleteUserFacts.DeletedFact(
              id: "fact2", 
              fact: "Prefers morning workouts"
            )
          ]
        ),
        hasPerformedAction: false
      )
    }
  }
}
