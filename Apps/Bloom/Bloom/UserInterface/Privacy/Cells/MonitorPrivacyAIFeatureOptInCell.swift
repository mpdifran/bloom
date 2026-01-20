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
      title: "Monitor Insights",
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
    let description = "AI insights into your monitor results. Monitor calculations run entirely on-device."
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
