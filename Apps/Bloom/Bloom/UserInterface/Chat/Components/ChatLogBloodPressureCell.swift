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
  let dbID: String?

  init(
    chatMessageID: String,
    systolic: Double,
    diastolic: Double,
    hasPerformedAction: Bool,
    dbID: String?
  ) {
    self.chatMessageID = chatMessageID
    self.systolic = systolic
    self.diastolic = diastolic
    self.dbID = dbID
    self._hasLoggedBloodPressure = State(initialValue: hasPerformedAction)
  }

  @State private var saveComplete = false
  @State private var saveUndone = false
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

        Group {
          if hasLoggedBloodPressure, let _ = dbID {
            AsyncButton {
              try await undoLogBloodPressure()
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
            .disabled(hasLoggedBloodPressure)
          }
        }
        .sensoryFeedback(.impact, trigger: saveUndone)
        .sensoryFeedback(.success, trigger: saveComplete)
      }
      .cardContainer()
    }
    .padding(.horizontal)
    .tint(.mutedPink)
  }
}

private extension ChatLogBloodPressureCell {

  func logBloodPressure() async throws {
    let systolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: systolic)
    let diastolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: diastolic)

    let correlationType = HKCorrelationType(.bloodPressure)
    
    let systolicSample = HKQuantitySample(
      type: HKQuantityType(.bloodPressureSystolic),
      quantity: systolicQuantity,
      start: .now,
      end: .now
    )
    let diastolicSample = HKQuantitySample(
      type: HKQuantityType(.bloodPressureDiastolic),
      quantity: diastolicQuantity,
      start: .now,
      end: .now
    )

    let bloodPressure = HKCorrelation(
      type: correlationType,
      start: .now,
      end: .now,
      objects: [systolicSample, diastolicSample],
      metadata: [
        HKMetadataKeyWasUserEntered: true
      ]
    )

    try await HealthStoreModifier.shared.write(bloodPressure)
    TelemetryDeck.signal("Log Blood Pressure")

    hasLoggedBloodPressure = true
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasLoggedBloodPressure)
    try modelContext.storeDBID(id: chatMessageID, dbID: bloodPressure.uuid.uuidString)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }

  func undoLogBloodPressure() async throws {
    guard let dbID, let uuid = UUID(uuidString: dbID) else { return }
    
    // Delete the correlation from HealthKit
    try await HealthStoreModifier.shared.deleteSample(
      uuid: uuid,
      ofType: HKCorrelationType(.bloodPressure)
    )
    
    hasLoggedBloodPressure = false
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasLoggedBloodPressure)
    
    saveUndone.toggle()
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
          hasPerformedAction: false,
          dbID: nil
        )
        ChatLogBloodPressureCell(
          chatMessageID: "5678",
          systolic: 134,
          diastolic: 82,
          hasPerformedAction: true,
          dbID: "sample-uuid"
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
