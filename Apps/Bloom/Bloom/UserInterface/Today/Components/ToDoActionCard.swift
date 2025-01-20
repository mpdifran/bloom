//
//  ToDoActionCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-19.
//

import SwiftUI
import DataContainer

struct ToDoActionCard: View {
  let title: String
  let subtitle: String
  let systemImage: String
  let isComplete: Bool
  let vitalKind: VitalModel.Kind?

  var body: some View {
    HStack {
      CompletionCheckmarkView(state: isComplete ? .metGoal : .unmetGoal, colorize: true)

      VStack(alignment: .leading) {
        Text(title)
          .font(.title3)

        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .bold()
      .fontDesign(.rounded)
      .lineLimit(1)

      Spacer()

      DisclosureIndicator()
    }
    .frame(width: 280)
    .cardContainer()
  }
}

#Preview {
  ScrollView {
    VStack {
      ScrollView(.horizontal) {
        HStack {
          ToDoActionCard(
            title: "Log Weight",
            subtitle: "Daily",
            systemImage: "gauge.with.dots.needle.bottom.50percent.badge.plus",
            isComplete: false,
            vitalKind: nil
          )
          .tint(.mutedIndigo)
          ToDoActionCard(
            title: "Log Blood Pressure",
            subtitle: "Weekly",
            systemImage: "gauge.with.dots.needle.bottom.50percent.badge.plus",
            isComplete: true,
            vitalKind: .nutrition
          )
          .tint(.mutedBlue)
        }
        .padding()
      }
      .scrollIndicators(.hidden)
    }
  }
  .groupedBackground()
}
