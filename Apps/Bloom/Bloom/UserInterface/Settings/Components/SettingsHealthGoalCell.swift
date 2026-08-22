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
  /// LocalizedStringKey, not String: a String literal is passed straight to Text without a
  /// catalog lookup, so the value rendered in English regardless of language.
  let value: LocalizedStringKey
  /// Stays String: call sites pass already-localized runtime copy (the user's health focus).
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
          .lineLimit(1)

        Text(subtitle)
          .foregroundStyle(.secondary)
          .font(.subheadline)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
          .minimumScaleFactor(0.75)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(height: 110)
    .cardContainer()
    .selectable()
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        HStack {
          SettingsHealthGoalCell(
            image: Image(.logWeightIcon),
            value: "152 lbs",
            subtitle: "Maintain weight and learn to fly"
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
}
