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

    TodayInsightsPrivacyAIFeatureOptInCell(extraContext: String(localized: "Bud uses the Personal Data you turn on to generate personalized daily insights.", comment: "Extra explanation under the Today Insights toggle."))
      .cardContainer()

    ChatPrivacyAIFeatureOptInCell(extraContext: String(localized: "Bud uses the Personal Data you turn on to answer your health and wellness questions.", comment: "Extra explanation under the Chat toggle."))
      .cardContainer()

    MonitorPrivacyAIFeatureOptInCell(extraContext: String(localized: "Bud uses the Personal Data you turn on to provide insights on your current monitor state.", comment: "Extra explanation under the Monitor toggle."))
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
        title: String(localized: "Before You Continue", comment: "Title of the consent confirmation alert."),
        message: confirmationAlertBody,
        buttons: [
          AlertDetails.Button(title: String(localized: "Edit Choices", comment: "Alert button that returns the user to the data sharing toggles."), role: .cancel, action: {
            continuation.resume(returning: false)
          }),
          AlertDetails.Button(title: String(localized: "Agree", comment: "Alert button confirming consent."), action: {
            continuation.resume(returning: true)
          })
        ]
      )
    }
  }

  var confirmationAlertBody: String {
    let numCategories = aiDataSharingSettings.enabledCategories.count
    let personalDataCategoriesText = numCategories == 1
      ? String(localized: "1 Personal Data category", comment: "Fragment used inside the consent confirmation alert.")
      : String(localized: "\(numCategories) Personal Data categories", comment: "Fragment used inside the consent confirmation alert.")

    return String(localized: "Bud will only use the \(personalDataCategoriesText) you turned on to generate personalized responses to your questions about health and wellness, and to generate personalized insights.\n\nDo you agree to Bud using the Personal Data categories you selected for these purposes?", comment: "Body of the consent confirmation alert. Placeholder is a count of Personal Data categories.")
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
