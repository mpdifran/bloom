//
//  BiologicalAgePrivacyAIFeatureOptInCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-08.
//

import SwiftUI
import BloomUI

struct BiologicalAgePrivacyAIFeatureOptInCell: View {
  let extraContext: String?

  init(extraContext: String? = nil) {
    self.extraContext = extraContext
  }

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  var body: some View {
    PrivacyAIFeatureOptInCell(
      title: "Biological Age",
      subtitle: subtitle,
      isEnabled: $aiFeatureSettings.biologicalAgeEnabled) {
        BiologicalAgeIcon(isEnabled: aiFeatureSettings.biologicalAgeEnabled)
          .frame(width: 40)
      }
      .tint(.mutedGreen)
  }
}

private extension BiologicalAgePrivacyAIFeatureOptInCell {

  var subtitle: String {
    if let extraContext {
      return "Estimate your biological age. \(extraContext)"
    }
    return "Estimate your biological age."
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BiologicalAgePrivacyAIFeatureOptInCell()
        .cardContainer()
    }
  }
}
