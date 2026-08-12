//
//  TodayInsightsPrivacyAIFeatureOptInCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-08.
//

import SwiftUI
import BloomUI

struct TodayInsightsPrivacyAIFeatureOptInCell: View {
  let extraContext: String?

  init(extraContext: String? = nil) {
    self.extraContext = extraContext
  }

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  var body: some View {
    PrivacyAIFeatureOptInCell(
      title: "Today Insights",
      subtitle: subtitle,
      isEnabled: $aiFeatureSettings.todayInsightsEnabled) {
        TodayInsightsIcon(isEnabled: aiFeatureSettings.todayInsightsEnabled)
          .frame(width: 40)
      }
      .tint(.mutedOrange)
  }
}

private extension TodayInsightsPrivacyAIFeatureOptInCell {

  var subtitle: String {
    if let extraContext {
      return "Personalized daily insights. \(extraContext)"
    }
    return String(localized: "Personalized daily insights based on your Personal Data.")
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      TodayInsightsPrivacyAIFeatureOptInCell()
        .cardContainer()
    }
  }
}
