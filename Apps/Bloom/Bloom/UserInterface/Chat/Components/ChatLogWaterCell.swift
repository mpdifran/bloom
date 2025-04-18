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

struct ChatLogWaterCell: View {
  let chatMessageID: String
  let waterQuantity: HKQuantity

  init(
    chatMessageID: String,
    waterQuantity: HKQuantity,
    hasPerformedAction: Bool
  ) {
    self.chatMessageID = chatMessageID
    self.waterQuantity = waterQuantity
    self._hasLoggedWater = State(initialValue: hasPerformedAction)
  }

  @State private var saveComplete = false
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
        .sensoryFeedback(.success, trigger: saveComplete)
        .disabled(hasLoggedWater)
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

    try modelContext.markChatMessageActionTaken(id: chatMessageID)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
    hasLoggedWater = true

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatLogWaterCell(
          chatMessageID: "1234",
          waterQuantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: 250),
          hasPerformedAction: false
        )
        ChatLogWaterCell(
          chatMessageID: "123456",
          waterQuantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: 250),
          hasPerformedAction: true
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
