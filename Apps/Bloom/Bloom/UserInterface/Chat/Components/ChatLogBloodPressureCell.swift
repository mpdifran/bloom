//
//  ChatLogBloodPressureCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-18.
//

import SwiftUI
import HealthKit
import SFSafeSymbols
import TelemetryDeck
import CoreHealth

struct ChatLogBloodPressureCell: View {
  let chatMessageID: String
  let systolic: Double
  let diastolic: Double

  init(
    chatMessageID: String,
    systolic: Double,
    diastolic: Double,
    hasPerformedAction: Bool
  ) {
    self.chatMessageID = chatMessageID
    self.systolic = systolic
    self.diastolic = diastolic
    self._hasLoggedBloodPressure = State(initialValue: hasPerformedAction)
  }

  @State private var saveComplete = false
  @State private var hasLoggedBloodPressure: Bool

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview

  var body: some View {
    HStack {
      VStack {
        Text("\(NumberFormatter.noDecimalPlaces.string(for: systolic) ?? "--") / \(NumberFormatter.noDecimalPlaces.string(for: diastolic) ?? "--")")
          .font(.largeTitle)
          .fontWeight(.heavy)
          .fontDesign(.rounded)
          .padding()

        AsyncButton {
          try await logBloodPressure()
        } label: {
          Group {
            if hasLoggedBloodPressure {
              Label("Logged", systemSymbol: .checkmark)
            } else {
              Text("Log Blood Pressure")
            }
          }
          .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .sensoryFeedback(.success, trigger: saveComplete)
        .disabled(hasLoggedBloodPressure)
      }
      .cardContainer()

      Spacer(minLength: 60)
    }
    .padding(.horizontal)
    .tint(.mutedPink)
  }
}

private extension ChatLogBloodPressureCell {

  func logBloodPressure() async throws {
    let systolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: systolic)
    let diastolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: diastolic)

    let systolicSample = HKQuantitySample(
      type: HKQuantityType(.bloodPressureSystolic),
      quantity: systolicQuantity,
      start: .now,
      end: .now,
      metadata: [
        HKMetadataKeyWasUserEntered: true
      ]
    )
    let diastolicSample = HKQuantitySample(
      type: HKQuantityType(.bloodPressureDiastolic),
      quantity: diastolicQuantity,
      start: .now,
      end: .now,
      metadata: [
        HKMetadataKeyWasUserEntered: true
      ]
    )

    try await HealthStoreModifier.shared.write([systolicSample, diastolicSample])
    TelemetryDeck.signal("Log Blood Pressure")

    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: true)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
    hasLoggedBloodPressure = true

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatLogBloodPressureCell(
          chatMessageID: "1234",
          systolic: 120,
          diastolic: 80,
          hasPerformedAction: false
        )
        ChatLogBloodPressureCell(
          chatMessageID: "5678",
          systolic: 134,
          diastolic: 82,
          hasPerformedAction: true
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
