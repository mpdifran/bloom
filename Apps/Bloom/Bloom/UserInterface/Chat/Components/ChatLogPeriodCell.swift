//
//  ChatLogPeriodCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-16.
//

import SwiftUI
import HealthKit
import BloomModel
import CoreHealth
import TelemetryDeck

struct ChatLogPeriodCell: View {
  let chatMessageID: String
  let dbID: String?

  init(
    chatMessageID: String,
    flow: HKCategoryValueMenstrualFlow,
    hasPerformedAction: Bool,
    dbID: String?
  ) {
    self.chatMessageID = chatMessageID
    self.dbID = dbID
    self._flowType = State(initialValue: flow)
    self._hasLoggedPeriod = State(initialValue: hasPerformedAction)
  }

  @State private var flowType: HKCategoryValueMenstrualFlow
  @State private var saveComplete = false
  @State private var saveUndone = false
  @State private var hasLoggedPeriod: Bool

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview

  private let allFlowTypes: [HKCategoryValueMenstrualFlow] = [.none, .light, .medium, .heavy]

  var body: some View {
    HStack {

      VStack {

        Text("Log Period")
          .font(.title2)
          .bold()
          .fontDesign(.rounded)

        HStack {
          Spacer()

          ForEach(allFlowTypes, id: \.self) { flow in
            MenstrualFlowIndicatorView(flow: flow, isSelected: flowType == flow)
              .onTapGesture {
                guard !hasLoggedPeriod else { return }

                self.flowType = flow
              }

            Spacer()
          }
        }
        .padding(.bottom)

        Group {
          if hasLoggedPeriod, let _ = dbID {
            AsyncButton {
              try await undoSave()
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
              try await save()
            } label: {
              Text("Log")
                .horizontallyCentered()
            }
            .buttonStyle(.primary)
            .disabled(hasLoggedPeriod)
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

private extension ChatLogPeriodCell {

  func save() async throws {
    let uuid = try await HealthStoreModifier.shared.log(flowType: flowType, date: .now)

    hasLoggedPeriod = true
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasLoggedPeriod)
    if let uuid {
      try modelContext.storeDBID(id: chatMessageID, dbID: uuid.uuidString)
    }

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }

  func undoSave() async throws {
    guard let dbID, let uuid = UUID(uuidString: dbID) else { return }
    
    // Delete the sample from HealthKit
    try await HealthStoreModifier.shared.deleteSample(
      uuid: uuid,
      ofType: HKCategoryType(.menstrualFlow)
    )
    
    hasLoggedPeriod = false
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasLoggedPeriod)
    
    saveUndone.toggle()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ChatLogPeriodCell(
        chatMessageID: "1234",
        flow: .medium,
        hasPerformedAction: false,
        dbID: nil
      )
      ChatLogPeriodCell(
        chatMessageID: "5678",
        flow: .heavy,
        hasPerformedAction: true,
        dbID: "sample-uuid"
      )
    }
  }
}
