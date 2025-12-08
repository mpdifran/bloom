//
//  YouSettingsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-27.
//

import SwiftUI
import BloomUI

struct YouSettingsView: View {

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
      .onChange(of: aiFeatureSettings.biologicalAgeEnabled) { _, _ in
        Task {
          await ConsentManager.shared.syncGranularConsentSilently()
        }
      }
    }
  }
}

private extension YouSettingsView {

  var featureSection: some View {
    VStack {
      SectionTitleView("Biological Age")
        .padding(.horizontal)

      SettingsSectionContainer {
        PrivacyAIFeatureOptInCell(
          title: "Biological Age",
          subtitle: "Estimate your biological age based on your data.",
          isEnabled: $aiFeatureSettings.biologicalAgeEnabled) {
            BiologicalAgeIcon()
              .frame(width: 40)
          }
          .tint(.mutedGreen)
          .padding(.vertical)
      }

      SettingsSectionContainer {
        SettingsCell("Data Shared with AI", subtitle: aiDataSharingSettings.enabledCategoriesText, iconType: .disclosure) {
          EmptyView()
        }
        .onTapGesture {
          navigationPushView = AIDataSharingView().asAny
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      YouSettingsView()
    }
  }
}
