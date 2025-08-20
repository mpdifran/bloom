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
  let dbID: String?

  init(
    chatMessageID: String,
    bristolStoolType: Int,
    duration: BowelMovement.Duration,
    hasPerformedAction: Bool,
    dbID: String?
  ) {
    self.chatMessageID = chatMessageID
    self.bristolStoolType = bristolStoolType
    self.duration = duration
    self.dbID = dbID
    self._hasLoggedBowelMovement = State(initialValue: hasPerformedAction)
  }

  @State private var saveComplete = false
  @State private var saveUndone = false
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

        Group {
          if hasLoggedBowelMovement, let _ = dbID {
            AsyncButton {
              try await undoLogBowelMovement()
            } label: {
              HStack {
                Image(systemSymbol: .arrowCounterclockwise)
                Text("Undo")
              }
              .horizontallyCentered()
            }
            .foregroundStyle(.tint)
            .bold()
          } else {
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
            .disabled(hasLoggedBowelMovement)
          }
        }
        .sensoryFeedback(.impact, trigger: saveUndone)
        .sensoryFeedback(.success, trigger: saveComplete)
      }
      .chatCardContainer()
    }
    .padding(.horizontal)
    .tint(.brown)
  }
}

private extension ChatLogBowelMovementCell {

  func logBowelMovement() async throws {
    let recordID = UUID().uuidString
    
    try modelContext.savingTransaction {
      let model = BowelMovement(
        date: .now,
        bristolStoolType: bristolStoolType,
        duration: duration,
        recordID: recordID
      )
      modelContext.insert(model)
    }

    await VitalsCalculator.shared.fetchSwiftDataTypes()

    TelemetryDeck.signal("Log Bowel Movement")

    hasLoggedBowelMovement = true
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasLoggedBowelMovement)
    try modelContext.storeDBID(id: chatMessageID, dbID: recordID)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }

  func undoLogBowelMovement() async throws {
    guard let dbID else { return }
    
    // Delete the bowel movement from SwiftData
    try modelContext.delete(
      model: BowelMovement.self,
      where: #Predicate<BowelMovement> { movement in
        movement.recordID == dbID
      }
    )
    
    hasLoggedBowelMovement = false
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasLoggedBowelMovement)
    
    saveUndone.toggle()
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
          hasPerformedAction: false,
          dbID: nil
        )
        ChatLogBowelMovementCell(
          chatMessageID: "5678",
          bristolStoolType: 2,
          duration: .moreThan10Min,
          hasPerformedAction: true,
          dbID: "sample-uuid"
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
