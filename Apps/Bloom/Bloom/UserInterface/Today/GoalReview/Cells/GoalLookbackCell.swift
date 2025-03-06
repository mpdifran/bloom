//
//  GoalLookbackCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import SFSafeSymbols
import SwiftUI
import DataContainer

struct GoalLookbackCell: View {
  let goal: HabitDTO
  let history: [HabitGoalMetSample]

  var body: some View {
    HStack {
      Image(systemSymbol: SFSymbol(rawValue: goal.targetMetric.systemImage))
        .font(.title)
        .foregroundStyle(.tint)
        .frame(square: 50)

      VStack(alignment: .leading) {
        Text(goal.targetMetric.name)
          .bold()
          .multilineTextAlignment(.leading)

        HabitGridRowWeekLookbackView(completionHistory: history)
      }

      Spacer()

      VStack(alignment: .trailing) {
        Text(goal.quantity.displayString(for: goal.unit, showUnits: false))
          .font(.title3)
          .fontDesign(.rounded)
          .bold()
          .foregroundStyle(.tint)
          .contentTransition(.numericText(value: goal.value))
          .animation(.default, value: goal.value)

        Text(goal.unit.sensibleUnitString)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .cardContainer()
    .tint(goal.targetMetric.color)
  }
}

#Preview {
  ScrollView {
    VStack {
      GoalLookbackCell(
        goal: .Preview.steps,
        history: [
          HabitGoalMetSample(date: Date().addingTimeInterval(-518_400), goalMet: false),
          HabitGoalMetSample(date: Date().addingTimeInterval(-432_000), goalMet: true),
          HabitGoalMetSample(date: Date().addingTimeInterval(-345_600), goalMet: true),
          HabitGoalMetSample(date: Date().addingTimeInterval(-259_200), goalMet: false),
          HabitGoalMetSample(date: Date().addingTimeInterval(-172_800), goalMet: true),
          HabitGoalMetSample(date: Date().addingTimeInterval(-86_400), goalMet: false),
          HabitGoalMetSample(date: Date(), goalMet: true)
        ]
      )
      GoalLookbackCell(
        goal: .Preview.heartRateZone5,
        history: [
          HabitGoalMetSample(date: Date().addingTimeInterval(-518_400), goalMet: false),
          HabitGoalMetSample(date: Date().addingTimeInterval(-432_000), goalMet: true),
          HabitGoalMetSample(date: Date().addingTimeInterval(-345_600), goalMet: true),
          HabitGoalMetSample(date: Date().addingTimeInterval(-259_200), goalMet: false),
          HabitGoalMetSample(date: Date().addingTimeInterval(-172_800), goalMet: true),
          HabitGoalMetSample(date: Date().addingTimeInterval(-86_400), goalMet: false),
          HabitGoalMetSample(date: Date(), goalMet: true)
        ]
      )
    }
    .horizontallyCentered()
    .padding()
  }
  .groupedBackground()
}
