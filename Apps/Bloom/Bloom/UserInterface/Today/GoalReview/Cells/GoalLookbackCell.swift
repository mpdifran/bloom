//
//  GoalLookbackCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import SwiftUI
import DataContainer

struct GoalLookbackCell: View {
  let goal: HabitDTO
  let history: [HabitGoalMetSample]

  var body: some View {
    HStack {
      Image(systemName: goal.targetMetric.systemImage)
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

      VStack {
        Text(percentage)
          .font(.title2)
          .fontDesign(.rounded)
          .bold()
          .foregroundStyle(.tint)
          .contentTransition(.numericText(value: goal.value))
          .animation(.default, value: goal.value)

        Text("Goal Met")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .cardContainer()
    .tint(goal.targetMetric.color)
  }
}

private extension GoalLookbackCell {

  var percentage: String {
    let trueCount = history.count(where: { $0.goalMet == true })
    let percent = Double(trueCount) / Double(history.count)

    return (NumberFormatter.noDecimalPlaces.string(from: NSNumber(value: percent * 100)) ?? "0") + "%"
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
