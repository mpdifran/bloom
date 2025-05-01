//
//  ChatLogWeightCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-18.
//

import SwiftUI
import AppUI
import HealthKit
import SFSafeSymbols
import TelemetryDeck
import CoreHealth

struct ChatLogWeightCell: View {
  let chatMessageID: String
  let weightQuantity: HKQuantity

  init(
    chatMessageID: String,
    weightQuantity: HKQuantity,
    hasPerformedAction: Bool
  ) {
    self.chatMessageID = chatMessageID
    self.weightQuantity = weightQuantity
    self._hasLoggedWeight = State(initialValue: hasPerformedAction)
  }

  @State private var saveComplete = false
  @State private var hasLoggedWeight: Bool

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview

  var body: some View {
    HStack {
      VStack {
        Text(weightQuantity.displayString(for: .pound()))
          .font(.largeTitle)
          .fontWeight(.heavy)
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .padding()

        AsyncButton {
          try await logWeight()
        } label: {
          Group {
            if hasLoggedWeight {
              Label("Weight Logged", systemSymbol: .checkmark)
            } else {
              Text("Log Weight")
            }
          }
          .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .sensoryFeedback(.success, trigger: saveComplete)
        .disabled(hasLoggedWeight)
      }
      .cardContainer()

      Spacer(minLength: 60)
    }
    .padding(.horizontal)
    .tint(.mutedIndigo)
  }
}

private extension ChatLogWeightCell {

  func logWeight() async throws {
    let date = Date.now
    let sample = HKQuantitySample(
      type: HKQuantityType(.bodyMass),
      quantity: weightQuantity,
      start: date,
      end: date,
      metadata: [
        HKMetadataKeyWasUserEntered: true
      ]
    )

    try await HealthStoreModifier.shared.write(sample)

    TelemetryDeck.signal("Log Weight")

    if await VitalsCalculator.shared.bodyCompositionSummary?.details.hasNoData != false {
      await VitalsCalculator.shared.forceFetchVitals()
    }

    try modelContext.markChatMessageActionTaken(id: chatMessageID)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
    hasLoggedWeight = true

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatLogWeightCell(
          chatMessageID: "1234",
          weightQuantity: HKQuantity(unit: .pound(), doubleValue: 179),
          hasPerformedAction: false
        )
        ChatLogWeightCell(
          chatMessageID: "5678",
          weightQuantity: HKQuantity(unit: .pound(), doubleValue: 160),
          hasPerformedAction: true
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
