//
//  SettingsHabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-23.
//

import SwiftUI

struct SettingsHabitCell: View {
  let image: Image
  let title: String
  let subtitle: String

  var body: some View {
    HStack {
      image
        .font(.title2)
        .bold()
        .foregroundStyle(.tint)
        .frame(width: 40)

      VStack(alignment: .leading) {
        Text(title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
          .minimumScaleFactor(0.5)

        Text(subtitle)
          .font(.subheadline)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer()

      DisclosureIndicator()
    }
    .cardContainer()
    .selectable()
  }
}

#Preview {
  ScrollView {
    VStack {
      SettingsHabitCell(
        image: Image(systemName: "figure.run"),
        title: "Running distance",
        subtitle: "3 km"
      )
      .tint(.mutedGreen)
    }
    .padding()
  }
  .groupedBackground()
}
