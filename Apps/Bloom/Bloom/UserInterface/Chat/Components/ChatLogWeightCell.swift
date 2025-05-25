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
  let dbID: String?

  init(
    chatMessageID: String,
    weightQuantity: HKQuantity,
    hasPerformedAction: Bool,
    dbID: String?
  ) {
    self.chatMessageID = chatMessageID
    self.weightQuantity = weightQuantity
    self.dbID = dbID
    self._hasLoggedWeight = State(initialValue: hasPerformedAction)
  }

  @State private var saveComplete = false
  @State private var saveUndone = false
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

        Group {
          if hasLoggedWeight, let _ = dbID {
            AsyncButton {
              try await undoLogWeight()
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
            .disabled(hasLoggedWeight)
          }
        }
        .sensoryFeedback(.impact, trigger: saveUndone)
        .sensoryFeedback(.success, trigger: saveComplete)
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

    hasLoggedWeight = true
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasLoggedWeight)
    try modelContext.storeDBID(id: chatMessageID, dbID: sample.uuid.uuidString)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }

  func undoLogWeight() async throws {
    guard let dbID, let uuid = UUID(uuidString: dbID) else { return }
    
    // Delete the sample from HealthKit
    try await HealthStoreModifier.shared.deleteSample(
      uuid: uuid,
      ofType: HKQuantityType(.bodyMass)
    )
    
    hasLoggedWeight = false
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasLoggedWeight)
    
    saveUndone.toggle()
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatLogWeightCell(
          chatMessageID: "1234",
          weightQuantity: HKQuantity(unit: .pound(), doubleValue: 179),
          hasPerformedAction: false,
          dbID: nil
        )
        ChatLogWeightCell(
          chatMessageID: "5678",
          weightQuantity: HKQuantity(unit: .pound(), doubleValue: 160),
          hasPerformedAction: true,
          dbID: "sample-uuid"
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
