//
//  ChatSettingsView.swift
//  Bloom
//
//  Created by Assistant on 2025-11-27.
//

import SwiftUI
import BloomUI

struct ChatSettingsView: View {

  @State private var navigationPushView: AnyView?

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared
  @ObservedObject private var aiDataSharingSettings = AIDataSharingSettings.shared

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        featureSection
      }
      .navigationTitle("Preferences")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination($navigationPushView)
      .presentationDragIndicator(.visible)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .onChange(of: aiFeatureSettings.chatEnabled) { _, _ in
        Task {
          await ConsentManager.shared.syncGranularConsentSilently()
        }
      }
    }
  }
}

private extension ChatSettingsView {

  var featureSection: some View {
    VStack {
      SectionTitleView("Chat with Bud")
        .padding(.horizontal)

      SettingsSectionContainer {
        PrivacyAIFeatureOptInCell(
          title: "Chat with Bud",
          subtitle: "Chat with Bud about your health and wellness.",
          isEnabled: $aiFeatureSettings.chatEnabled) {
            ChatWithBudIcon()
              .frame(width: 40)
          }
          .tint(.mutedLightBlue)
          .padding(.vertical)
      }



      AIDataShareCell()
        .cardContainer()
        .onTapGesture {
          navigationPushView = AIDataSharingView().asAny
        }
    }
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      ChatSettingsView()
    }
  }
}
