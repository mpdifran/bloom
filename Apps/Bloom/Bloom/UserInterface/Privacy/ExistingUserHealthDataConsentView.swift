//
//  ExistingUserHealthDataConsentView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-09.
//

import SwiftUI
import BloomUI
import TelemetryDeck
import AppUI

struct ExistingUserHealthDataConsentView: View {
  var onContinue: () -> Void

  @State private var didContinue = false
  @State private var error: Error?

  var body: some View {
    BloomScrollView(padding: .bottom) {
      ZStack {
        Image(.afternoonScenery)
          .resizable()
          .scaledToFit()
          .parallaxOverscroll()
          .zStackAlignment(.top)

        VStack(spacing: 20) {
          BudImage(.budHealthApp, dimension: 200)
          explanationSection
          detailsSection
        }
        .padding(.horizontal)
        .padding(.top, 160)
      }
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .sensoryFeedback(.impact, trigger: didContinue)
    .alert(error: $error)
    .shelf {
      shelfContent
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .onAppear {
      TelemetryDeck.signal("View ExistingUserHealthDataConsentView")
    }
  }
}

private extension ExistingUserHealthDataConsentView {

  @ViewBuilder
  var explanationSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(.healthAppIcon)
          .resizable()
          .frame(square: 40)
        Text("Your Data, Your Choice")
          .primaryOnboardingTextStyle()
        Spacer()
      }

      Text("To help you stay on top of your health and reach your goals, I need your permission for a few things.")
        .secondaryOnboardingTextStyle()
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
    }
    .fixedSize(horizontal: false, vertical: true)
  }

  var detailsSection: some View {
    VStack {
      PrivacyDetailCard(
        symbol: .trophyFill,
        title: "Set and Track Goals",
        detail: "Set goals for the metrics you care about and stay on track over time."
      )

      PrivacyDetailCard(
        symbol: .chartLineUptrendXyaxis,
        title: "Charts and Visualizations",
        detail: "I’ll help you visualize your health trends and show typical ranges for context."
      )

      PrivacyDetailCard(
        symbol: .squareAndArrowDownOnSquareFill,
        title: "Writing Data",
        detail: "Bloom can help record things like weight, hydration, or what you eat."
      )
    }
  }

  @ViewBuilder
  var shelfContent: some View {
    Text("I confirm I’m the age of majority where I live and consent to Bloom reading and writing my Health app data for the purposes described above.")
      .font(.caption)
      .bold()
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
      .horizontallyCentered()
      .padding(.horizontal)

    AsyncButton {
      didContinue.toggle()
      await recordOptIn()
      onContinue()
    } label: {
      Text("Continue")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)

    privacyEmailView
  }

  var privacyEmailView: some View {
    HStack {
      Link("Privacy Policy", destination: .privacyPolicy)
        .bold()
        .frame(height: 40)
        .horizontallyCentered()

      Link("Questions? Email Us!", destination: .emailBloom(subject: "Privacy Questions"))
        .bold()
        .frame(height: 40)
        .horizontallyCentered()
    }
    .font(.subheadline)
  }
}

private extension ExistingUserHealthDataConsentView {

  func recordOptIn() async {
    await ConsentManager.shared.recordConsent(
      healthData: true,
      healthDataConsentScreenVersion: "ExistingUserHealthDataConsentView.v1"
    )
  }
}

#Preview {
  PreviewEnvironment {
    ExistingUserHealthDataConsentView() { }
  }
}
