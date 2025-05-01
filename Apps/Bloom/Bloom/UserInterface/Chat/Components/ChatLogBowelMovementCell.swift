//
//  ChatLogBowelMovementCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-18.
//

import SwiftUI
import DataContainer
import TelemetryDeck
import CoreHealth

struct ChatLogBowelMovementCell: View {
  let chatMessageID: String
  let bristolStoolType: Int
  let duration: BowelMovement.Duration

  init(
    chatMessageID: String,
    bristolStoolType: Int,
    duration: BowelMovement.Duration,
    hasPerformedAction: Bool
  ) {
    self.chatMessageID = chatMessageID
    self.bristolStoolType = bristolStoolType
    self.duration = duration
    self._hasLoggedBowelMovement = State(initialValue: hasPerformedAction)
  }

  @State private var saveComplete = false
  @State private var hasLoggedBowelMovement: Bool

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview

  var body: some View {
    HStack {
      VStack {
        HStack {
          Image("Type \(bristolStoolType)")
            .resizable()
            .scaledToFit()
            .aspectRatio(1, contentMode: .fit)
            .frame(height: 50)
            .padding(6)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .background {
              RoundedRectangle(cornerRadius: 13)
                .fill(.white)
            }
            .overlay {
              RoundedRectangle(cornerRadius: 13)
                .stroke(.fill)
            }

          VStack(alignment: .leading) {
            Text("Bristol Stool Type \(bristolStoolType)")
              .bold()
              .fontDesign(.rounded)
            Text(duration.name)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()
        }

        AsyncButton {
          try await logBowelMovement()
        } label: {
          Group {
            if hasLoggedBowelMovement {
              Label("Logged", systemSymbol: .checkmark)
            } else {
              Text("Log Bowel Movement")
            }
          }
          .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .sensoryFeedback(.success, trigger: saveComplete)
        .disabled(hasLoggedBowelMovement)
      }
      .cardContainer()

      Spacer(minLength: 60)
    }
    .padding(.horizontal)
    .tint(.brown)
  }
}

private extension ChatLogBowelMovementCell {

  func logBowelMovement() async throws {
    try modelContext.savingTransaction {
      let model = BowelMovement(
        date: .now,
        bristolStoolType: bristolStoolType,
        duration: duration
      )
      modelContext.insert(model)
    }

    await VitalsCalculator.shared.fetchSwiftDataTypes()

    TelemetryDeck.signal("Log Bowel Movement")

    try modelContext.markChatMessageActionTaken(id: chatMessageID)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
    hasLoggedBowelMovement = true

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatLogBowelMovementCell(
          chatMessageID: "1234",
          bristolStoolType: 4,
          duration: .between5And10Min,
          hasPerformedAction: false
        )
        ChatLogBowelMovementCell(
          chatMessageID: "5678",
          bristolStoolType: 2,
          duration: .moreThan10Min,
          hasPerformedAction: true
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
