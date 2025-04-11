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
  let goals: [ProposedGoal]

  init(goals: [ProposedGoal]) {
    self.goals = goals
  }

  @State private var didAddGoals = false
  @State private var addGoalsToggle = false

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
    .sensoryFeedback(.success, trigger: addGoalsToggle)
    .disabled(didAddGoals)
  }
}

private extension ChatGoalsCell {

  func addGoals() throws {
    try HabitsViewModel.shared.apply(proposedGoals: goals)

    addGoalsToggle.toggle()
    SoundPlayer.playLogHealthData()
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatGoalsCell(
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
          ]
        )
      }
    }
    .groupedBackground()
  }
}
