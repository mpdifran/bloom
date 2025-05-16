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

struct ChatLogPeriodCell: View {
  let chatMessageID: String

  init(
    chatMessageID: String,
    flow: HKCategoryValueMenstrualFlow,
    hasPerformedAction: Bool
  ) {
    self.chatMessageID = chatMessageID
    self._flowType = State(initialValue: flow)
    self._hasLoggedPeriod = State(initialValue: hasPerformedAction)
  }

  @State private var flowType: HKCategoryValueMenstrualFlow
  @State private var saveComplete = false
  @State private var hasLoggedPeriod: Bool

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

        AsyncButton {
          try await save()
        } label: {
          Group {
            if hasLoggedPeriod {
              Label("Period Logged", systemSymbol: .checkmark)
            } else {
              Text("Log")
            }
          }
          .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .sensoryFeedback(.success, trigger: saveComplete)
        .disabled(hasLoggedPeriod)
      }
      .cardContainer()

      Spacer(minLength: 60)
    }
    .padding(.horizontal)
    .tint(.mutedPink)
  }
}

private extension ChatLogPeriodCell {

  func save() async throws {
    try await HealthStoreModifier.shared.log(flowType: flowType, date: .now)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ChatLogPeriodCell(
        chatMessageID: "1234",
        flow: .medium,
        hasPerformedAction: false
      )
      ChatLogPeriodCell(
        chatMessageID: "5678",
        flow: .heavy,
        hasPerformedAction: true
      )
    }
  }
}
