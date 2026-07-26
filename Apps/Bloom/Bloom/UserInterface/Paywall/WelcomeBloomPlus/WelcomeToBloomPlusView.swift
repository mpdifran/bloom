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
import TelemetryDeck

struct WelcomeToBloomPlusView: View {

  let onDismiss: () -> Void

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared
  @ObservedObject private var aiDataSharingSettings = AIDataSharingSettings.shared

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  @State private var presentedSheet: AnyView?
  @State private var alertDetails: AlertDetails?
  @State private var confettiIndex = 0

  var body: some View {
    BloomScrollView(padding: .bottom) {
      Image(.budClub)
        .resizable()
        .scaledToFit()
        .standardConfetti($confettiIndex, colors: [.mutedOrange, .mutedBlue, .mutedPurple, .mutedPink])
        .parallaxOverscroll()

      VStack {
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
    .alert(alertDetails: $alertDetails)
    .presentationCompactAdaptation(.fullScreenCover)
    .sensoryFeedback(.impact, trigger: confettiIndex)
    .task {
      confettiIndex += 1
      await Delay(1500)
      confettiIndex += 1
      await Delay(1000)
      confettiIndex += 1
    }
    .onAppear {
      TelemetryDeck.signal("View WelcomeToBloomPlusView")
    }
  }
}

private extension WelcomeToBloomPlusView {

  @ViewBuilder
  var explanationSection: some View {
    BloomPlusLogo()
      .horizontallyCentered()

    Text("Welcome to the Club!")
      .onboardingTextStyle()
      .multilineTextAlignment(.center)
    Text("You’ve unlocked deeper insights, smarter guidance, and Bud’s full brainpower.")
      .secondaryOnboardingTextStyle()
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
      .multilineTextAlignment(.center)
  }

  @ViewBuilder
  var sharingSection: some View {
    SectionTitleView("Sharing With Bud")
      .padding(.horizontal)

    AIDataShareCell()
      .cardContainer()
      .onTapGesture {
        presentedSheet = AIDataSharingView(showDismiss: true).asAny
      }
  }

  @ViewBuilder
  var aiFeaturesSection: some View {
    SectionTitleView("Features")
      .padding(.horizontal)

    TodayInsightsPrivacyAIFeatureOptInCell(extraContext: "Bud uses the Personal Data you turn on to generate personalized daily insights.")
      .cardContainer()

    ChatPrivacyAIFeatureOptInCell(extraContext: "Bud uses the Personal Data you turn on to answer your health and wellness questions.")
      .cardContainer()

    MonitorPrivacyAIFeatureOptInCell(extraContext: "Bud uses the Personal Data you turn on to provide insights on your current monitor state.")
      .cardContainer()
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
      if aiDataSharingSettings.enabledCategories.isNotEmpty {
        if await !showConfirmationAlert() {
          return
        }
      }

      try await logConfirmation()
      dismiss()
      onDismiss()
    } label: {
      Text("Continue")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }
}

private extension WelcomeToBloomPlusView {

  func showConfirmationAlert() async -> Bool {
    await withCheckedContinuation { continuation in
      alertDetails = AlertDetails(
        title: "Before You Continue",
        message: confirmationAlertBody,
        buttons: [
          AlertDetails.Button(title: "Edit Choices", role: .cancel, action: {
            continuation.resume(returning: false)
          }),
          AlertDetails.Button(title: "Agree", action: {
            continuation.resume(returning: true)
          })
        ]
      )
    }
  }

  var confirmationAlertBody: String {
    let numCategories = aiDataSharingSettings.enabledCategories.count
    let personalDataCategoriesText = numCategories == 1 ? "1 Personal Data category" : "\(numCategories) Personal Data categories"

    return "Bud will only use the \(personalDataCategoriesText) you turned on to generate personalized responses to your questions about health and wellness, and to generate personalized insights.\n\nDo you agree to Bud using the Personal Data categories you selected for these purposes?"
  }

  func logConfirmation() async throws {
    try await ConsentManager.shared.recordGranularConsent(externalHealthDataScreenVersion: "WelcomeToBloomPlusView.v1")
  }
}

#Preview {
  PreviewEnvironment {
    WelcomeToBloomPlusView() { }
  }
}
