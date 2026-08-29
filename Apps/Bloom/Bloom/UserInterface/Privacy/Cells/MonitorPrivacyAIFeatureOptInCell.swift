//
//  MonitorPrivacyAIFeatureOptInCell.swift
//  Bloom
//
//  Created by Claude on 2026-01-18.
//

import SwiftUI
import BloomUI

struct MonitorPrivacyAIFeatureOptInCell: View {
  let extraContext: String?

  init(extraContext: String? = nil) {
    self.extraContext = extraContext
  }

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  var body: some View {
    PrivacyAIFeatureOptInCell(
      title: String(localized: "Monitor Insights", comment: "AI feature name in the data sharing settings"),
      subtitle: subtitle,
      isEnabled: $aiFeatureSettings.monitorEnabled) {
        MonitorIcon(isEnabled: aiFeatureSettings.monitorEnabled)
          .frame(width: 40)
      }
      .tint(.monitorHigh)
  }
}

private extension MonitorPrivacyAIFeatureOptInCell {

  var subtitle: String {
    let description = String(localized: "AI insights into your monitor results. Monitor calculations run entirely on-device.", comment: "Subtitle for monitor privacy AI feature opt in cell")
    if let extraContext {
      return description + extraContext
    }
    return description
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MonitorPrivacyAIFeatureOptInCell()
        .cardContainer()
    }
  }
}
