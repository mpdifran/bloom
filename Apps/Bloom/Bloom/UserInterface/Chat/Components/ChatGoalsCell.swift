//
//  ChatGoalsCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-11.
//

import SwiftUI
import AppUI
import SFSafeSymbols

struct ChatGoalsCell: View {
  let chatMessageID: String
  let goals: [ProposedGoal]
  let hasPerformedAction: Bool

  init(
    chatMessageID: String,
    goals: [ProposedGoal],
    hasPerformedAction: Bool
  ) {
    self.chatMessageID = chatMessageID
    self.goals = goals
    self.hasPerformedAction = hasPerformedAction

    self._didAddGoals = State(initialValue: hasPerformedAction)
  }

  @State private var didAddGoals: Bool

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview

  var body: some View {
    HStack {
      VStack {
        goalsSection

        addGoalsButton
          .padding(.top)
      }
      .cardContainer()

      Spacer(minLength: 60)
    }
    .padding(.horizontal)
    .animation(.default, value: didAddGoals)
  }
}

private extension ChatGoalsCell {

  var goalsSection: some View {
    ForEachEnumerated(goals) { index, goal in
      if index != 0 {
        Divider()
      }

      HStack {
        Image(systemSymbol: SFSymbol(rawValue: goal.targetMetric.systemImage))
          .font(.title)
          .foregroundStyle(.tint)
          .frame(width: 40)

        Text(goal.targetMetric.name)
          .font(.body)
          .bold()
          .fontDesign(.rounded)

        Spacer()

        VStack {
          Text(goal.displayQuantityNoUnits)
            .font(.title3)
            .fontWeight(.heavy)
            .foregroundStyle(.tint)
            .fontDesign(.rounded)
          Text(goal.unit.localizedUnit().sensibleUnitString)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .tint(goal.targetMetric.color)
    }
  }

  var addGoalsButton: some View {
    AsyncButton {
      try addGoals()
    } label: {
      Group {
        if didAddGoals {
          Label("Goals Added", systemSymbol: .checkmark)
        } else {
          Label("Add Goals", systemSymbol: .plus)
        }
      }
      .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .sensoryFeedback(.success, trigger: didAddGoals)
    .animation(.default, value: didAddGoals)
    .disabled(didAddGoals)
  }
}

private extension ChatGoalsCell {

  func addGoals() throws {
    try HabitsViewModel.shared.apply(proposedGoals: goals)
    try modelContext.markChatMessageActionTaken(id: chatMessageID)

    SoundPlayer.playLogHealthData()
    didAddGoals = true

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatGoalsCell(
          chatMessageID: "1234",
          goals: [
            ProposedGoal(
              habitID: nil,
              targetMetric: .bikeDistance,
              value: 10,
              suggestedValue: 10,
              previousValue: nil,
              unitString: "km",
              vitalKind: nil,
              context: nil,
              hasUserEdited: false
            ),
            ProposedGoal(
              habitID: nil,
              targetMetric: .runDuration,
              value: 15,
              suggestedValue: 15,
              previousValue: nil,
              unitString: "min",
              vitalKind: nil,
              context: nil,
              hasUserEdited: false
            )
          ],
          hasPerformedAction: false
        )
      }
    }
    .groupedBackground()
  }
}
