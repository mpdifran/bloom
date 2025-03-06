//
//  SettingsHealthGoalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-23.
//

import SFSafeSymbols
import SwiftUI

struct SettingsHealthGoalCell: View {
  let image: Image
  let value: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        image
          .font(.title2)
          .bold()
          .foregroundStyle(.tint)

        Spacer()

        DisclosureIndicator()
          .foregroundStyle(.tertiary)
          .bold()
      }

      Spacer()

      VStack(alignment: .leading) {
        Text(value)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
          .minimumScaleFactor(0.5)

        HStack(spacing: 4) {
          Text(subtitle)
            .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)
        .lineLimit(1)
      }
    }
    .frame(height: 90)
    .cardContainer()
    .selectable()
  }
}

#Preview {
  ScrollView {
    VStack {
      HStack {
        SettingsHealthGoalCell(
          image: Image(.logWeightIcon),
          value: "152 lbs",
          subtitle: "Maintain weight"
        )
        .tint(.mutedIndigo)

        SettingsHealthGoalCell(
          image: Image(systemSymbol: .figureHighintensityIntervaltraining),
          value: "High",
          subtitle: "Activity level"
        )
        .tint(.activityLevelHigh)
      }
    }
    .padding()
  }
  .groupedBackground()
}
