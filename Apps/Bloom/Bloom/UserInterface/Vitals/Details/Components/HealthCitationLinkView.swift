//
//  HealthCitationLinkView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-14.
//

import SwiftUI

struct HealthCitationLinkView: View {
  let url: URL
  let title: String

  var body: some View {
    Link(destination: url) {
      Group {
        Text(title)
          .foregroundStyle(.text.secondary)
        +
        Text(" Source")
      }
      .multilineTextAlignment(.leading)
    }
    .horizontalAlignment(.leading)
    .font(.caption)
    .bold()
    .fontDesign(.rounded)
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
