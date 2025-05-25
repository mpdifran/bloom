//
//  ChatLogWaterCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-18.
//

import SwiftUI
import HealthKit
import SFSafeSymbols
import TelemetryDeck
import CoreHealth

struct ChatLogWaterCell: View {
  let chatMessageID: String
  let waterQuantity: HKQuantity
  let dbID: String?

  init(
    chatMessageID: String,
    waterQuantity: HKQuantity,
    hasPerformedAction: Bool,
    dbID: String?
  ) {
    self.chatMessageID = chatMessageID
    self.waterQuantity = waterQuantity
    self.dbID = dbID
    self._hasLoggedWater = State(initialValue: hasPerformedAction)
  }

  @State private var saveComplete = false
  @State private var saveUndone = false
  @State private var hasLoggedWater: Bool

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview

  var body: some View {
    HStack {
      VStack {
        Text(waterQuantity.displayString(for: .literUnit(with: .milli)))
          .font(.largeTitle)
          .fontWeight(.heavy)
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .padding()

        Group {
          if hasLoggedWater, let _ = dbID {
            AsyncButton {
              try await undoLogWater()
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
              try await logWater()
            } label: {
              Group {
                if hasLoggedWater {
                  Label("Water Logged", systemSymbol: .checkmark)
                } else {
                  Text("Log Water")
                }
              }
              .horizontallyCentered()
            }
            .buttonStyle(.primary)
            .disabled(hasLoggedWater)
          }
        }
        .sensoryFeedback(.impact, trigger: saveUndone)
        .sensoryFeedback(.success, trigger: saveComplete)
      }
      .cardContainer()

      Spacer(minLength: 60)
    }
    .padding(.horizontal)
    .tint(.mutedBlue)
  }
}

private extension ChatLogWaterCell {

  func logWater() async throws {
    let sample = HKQuantitySample(
      type: HKQuantityType(.dietaryWater),
      quantity: waterQuantity,
      start: Date.now,
      end: Date.now,
      metadata: [
        HKMetadataKeyWasUserEntered: true
      ]
    )

    try await HealthStoreModifier.shared.write(sample)

    TelemetryDeck.signal("Log Water")

    hasLoggedWater = true
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasLoggedWater)
    try modelContext.storeDBID(id: chatMessageID, dbID: sample.uuid.uuidString)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }

  func undoLogWater() async throws {
    guard let dbID, let uuid = UUID(uuidString: dbID) else { return }
    
    // Delete the sample from HealthKit
    try await HealthStoreModifier.shared.deleteSample(
      uuid: uuid,
      ofType: HKQuantityType(.dietaryWater)
    )
    
    hasLoggedWater = false
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasLoggedWater)
    
    saveUndone.toggle()
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatLogWaterCell(
          chatMessageID: "1234",
          waterQuantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: 250),
          hasPerformedAction: false,
          dbID: nil
        )
        ChatLogWaterCell(
          chatMessageID: "123456",
          waterQuantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: 250),
          hasPerformedAction: true,
          dbID: "sample-uuid"
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
