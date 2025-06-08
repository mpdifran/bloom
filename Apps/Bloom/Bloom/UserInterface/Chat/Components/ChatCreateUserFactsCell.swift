//
//  ChatCreateUserFactsCell.swift
//  Bloom
//
//  Created by Claude on 2025-06-08.
//

import SwiftUI
import BloomModel
import DataContainer
import SFSafeSymbols

struct ChatCreateUserFactsCell: View {
  let chatMessageID: String
  let userFacts: SocketMessage.CreateUserFacts

  var body: some View {
    ForEach(userFacts.facts, id: \.fact) { fact in
      HStack {
        Image(systemSymbol: .brainHeadProfileFill)
          .foregroundStyle(.tint)

        VStack(alignment: .leading) {
          Text("Memory Updated")
            .font(.caption)
            .foregroundStyle(.secondary)

          Text(fact.fact)
            .font(.body)
            .bold()
            .fontDesign(.rounded)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
        }

        Spacer(minLength: 0)

        DisclosureIndicator()
      }
      .cardContainer()
      .tint(.mutedYellow)
    }
  }
}

extension DateFormatter {
  static let mediumDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
  }()
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ChatCreateUserFactsCell(
        chatMessageID: "test",
        userFacts: SocketMessage.CreateUserFacts(
          facts: [
            SocketMessage.CreateUserFacts.UserFactInput(
              fact: "User has a knee injury from running",
              revisitDate: Date()
            ),
            SocketMessage.CreateUserFacts.UserFactInput(
              fact: "Prefers morning workouts",
              revisitDate: Date()
            )
          ]
        )
      )
    }
  }
}
