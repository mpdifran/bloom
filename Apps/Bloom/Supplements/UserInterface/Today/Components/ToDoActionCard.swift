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
    VStack(alignment: .leading, spacing: 26) {
      HStack {
        Image(systemName: systemImage)
          .font(.title2)
          .bold()
          .foregroundStyle(.tint)

        Spacer()

        DisclosureIndicator()
          .foregroundStyle(.tertiary)
          .bold()
      }

      VStack(alignment: .leading) {
        Text(title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)

        HStack(spacing: 4) {
          Text(subtitle)
            .foregroundStyle(.secondary)

          if isComplete {
            Text("•")
            Text("Complete")
              .foregroundStyle(.tint)
          }
        }
        .font(.subheadline)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)
      }
    }
    .frame(width: 180)
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
            title: "Log Weight",
            subtitle: "Daily",
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
