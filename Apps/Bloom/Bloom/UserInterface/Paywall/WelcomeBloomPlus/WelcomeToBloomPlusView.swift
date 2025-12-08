//
//  WelcomeToBloomPlusView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-03.
//

import SwiftUI
import BloomFoundation
import BloomUI
import CoreHealth
import SFSafeSymbols
import AppUI

struct WelcomeToBloomPlusView: View {

  let onDismiss: () -> Void

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared
  @ObservedObject private var aiDataSharingSettings = AIDataSharingSettings.shared

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  @State private var presentedSheet: AnyView?
  @State private var confettiIndex = 0

  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .bottom) {
      Image(.budClub)
        .resizable()
        .scaledToFit()
        .standardConfetti($confettiIndex, colors: [.mutedOrange, .mutedBlue, .mutedPurple, .mutedPink])
        .parallaxOverscroll()

      VStack(alignment: .leading, spacing: 10) {
        explanationSection
        sharingSection
        aiFeaturesSection
        legalSection
      }
      .horizontalAlignment(.leading)
      .padding(.horizontal)
      .padding(.top)
    }
    .ignoresSafeArea(.all, edges: .top)
    .shelf {
      shelfContent
    }
    .sheet($presentedSheet)
    .presentationCompactAdaptation(.fullScreenCover)
    .sensoryFeedback(.impact, trigger: confettiIndex)
    .task {
      confettiIndex += 1
      await Delay(1500)
      confettiIndex += 1
      await Delay(1000)
      confettiIndex += 1
    }
  }
}

private extension WelcomeToBloomPlusView {

  @ViewBuilder
  var explanationSection: some View {
    Text("Welcome to the Club!")
      .onboardingTextStyle()
    Text("You’ve unlocked deeper insights, smarter guidance, and Bud’s full brainpower.")
      .secondaryOnboardingTextStyle()
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
  }

  @ViewBuilder
  var aiFeaturesSection: some View {
    SectionTitleView("Features")
      .padding(.horizontal)
    PrivacyAIFeatureOptInCell(
      title: "Today Insights",
      subtitle: "Personalized daily insights from your data.",
      isEnabled: $aiFeatureSettings.todayInsightsEnabled) {
        TodayInsightsIcon()
          .frame(width: 40)
      }
      .tint(.mutedOrange)
      .cardContainer()

    PrivacyAIFeatureOptInCell(
      title: "Chat with Bud",
      subtitle: "Chat with Bud about your health and wellness.",
      isEnabled: $aiFeatureSettings.chatEnabled) {
        ChatWithBudIcon()
          .frame(width: 40)
      }
      .tint(.mutedLightBlue)
      .cardContainer()

    PrivacyAIFeatureOptInCell(
      title: "Biological Age",
      subtitle: "Estimate your biological age based on your data.",
      isEnabled: $aiFeatureSettings.biologicalAgeEnabled) {
        BiologicalAgeIcon()
          .frame(width: 40)
      }
      .tint(.mutedGreen)
      .cardContainer()

    Text("Choose which features can use the data enabled above.")
      .font(.caption)
      .bold()
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.horizontal)
  }

  @ViewBuilder
  var sharingSection: some View {
    SectionTitleView("Sharing Personal Data")
      .padding(.horizontal)

    AIDataShareCell()
      .cardContainer()
      .onTapGesture {
        presentedSheet = AIDataSharingView(showDismiss: true).asAny
      }

    Text("Choose what Personal Data Bud can use with the features below.")
      .font(.caption)
      .bold()
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.horizontal)
  }

  @ViewBuilder
  var legalSection: some View {
    HStack {
      Button {
        openURL(.termsOfService)
      } label: {
        Text("Terms of Service")
          .horizontallyCentered()
      }
      .buttonStyle(.primaryAlternate)

      Button {
        openURL(.privacyPolicy)
      } label: {
        Text("Privacy Policy")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .padding(.top)
    .padding(.top)
  }

  @ViewBuilder
  var shelfContent: some View {
    AsyncButton {
      try await ConsentManager.shared.recordGranularConsent(externalHealthDataScreenVersion: "WelcomeToBloomPlusView.v1")
      dismiss()
      onDismiss()
    } label: {
      Text("Continue")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }
}

#Preview {
  PreviewEnvironment {
    WelcomeToBloomPlusView() { }
  }
}
