//
//  ChatPrivacyAIFeatureOptInCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-08.
//

import SwiftUI
import BloomUI

struct ChatPrivacyAIFeatureOptInCell: View {
  let extraContext: String?

  init(extraContext: String? = nil) {
    self.extraContext = extraContext
  }

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  var body: some View {
    PrivacyAIFeatureOptInCell(
      title: "Chat with Bud",
      subtitle: subtitle,
      isEnabled: $aiFeatureSettings.chatEnabled) {
        ChatWithBudIcon(isEnabled: aiFeatureSettings.chatEnabled)
          .frame(width: 40)
      }
      .tint(.mutedLightBlue)
  }
}

private extension ChatPrivacyAIFeatureOptInCell {

  var subtitle: String {
    if let extraContext {
      return "Chat with Bud about your health and wellness. \(extraContext)"
    }
    return "Chat with Bud about your health and wellness."
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ChatPrivacyAIFeatureOptInCell()
        .cardContainer()
    }
  }
}
