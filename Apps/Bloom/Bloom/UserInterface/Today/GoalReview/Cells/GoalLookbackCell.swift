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

        HabitGridRowWeekLookbackView(
          completionHistory: [true, false, false, true, true, true, false]
        )
      }

      Spacer()

      VStack {
        Text("27%")
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

#Preview {
  ScrollView {
    VStack {
      GoalLookbackCell(goal: .Preview.steps)
      GoalLookbackCell(goal: .Preview.heartRateZone5)
    }
    .horizontallyCentered()
    .padding()
  }
  .groupedBackground()
}
