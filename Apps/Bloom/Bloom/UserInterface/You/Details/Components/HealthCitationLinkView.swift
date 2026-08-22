//
//  HealthCitationLinkView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-14.
//

import SwiftUI
import BloomUI

struct HealthCitationLinkView: View {
  let url: URL
  /// LocalizedStringKey, not String: a String literal is passed straight to Text without a
  /// catalog lookup, so every citation rendered in English regardless of language.
  let title: LocalizedStringKey

  var body: some View {
    Link(destination: url) {
      Group {
        Text(
          "\(Text(title).foregroundStyle(.secondary)) \(Text("Source").bold().foregroundStyle(.tint))",
          comment: "Citation line. The first placeholder is the citation title, the second is the word \"Source\" shown as a link."
        )
      }
      .multilineTextAlignment(.leading)
    }
    .buttonStyle(.plain)
    .horizontalAlignment(.leading)
    .font(.caption)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HealthCitationLinkView(url: .adultActivityLevels, title: "Adult Activity Levels")

      DetailInfoCardView {
        Text("Energy Ratio is the ratio between your Basal Energy and TDEE (Total Daily Energy Exertion) for a given day. The higher the ratio, the more active you were.")

        HealthCitationLinkView(url: .faoHumanEnergyRequirements, title: "Based on Physical Activity Level (PAL) definitions from the FAO/WHO/UNU Expert Consultation on Human Energy Requirements (2001).")
      }
    }
  }
}
