//
//  OnboardingTrustView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-20.
//

import SwiftUI
import AppUI
import BloomUI
import BloomModel
import BloomFoundation
import TelemetryDeck
import CoreHealth
import SFSafeSymbols

struct OnboardingTrustView: View {
  let onContinue: () -> Void

  @State private var index = 0
  @State private var didContinueToggle = false

  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .bottom) {
      ZStack {
        Image(.afternoonScenery)
          .resizable()
          .scaledToFit()
          .offset(y: -40)
          .parallaxOverscroll()
          .zStackAlignment(.top)

        VStack(alignment: .leading) {
          BudImage(.budYoga, dimension: 200)
            .horizontallyCentered()
          messagesSection
        }
        .horizontalAlignment(.leading)
        .padding(.top, 100)
        .padding(.horizontal)
      }
    }
    .shelf {
      Button {
        didContinueToggle.toggle()
        onContinue()
      } label: {
        Text("Got it")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.impact, trigger: didContinueToggle)
    .task {
      await advanceIndex()
    }
    .onAppear {
      TelemetryDeck.signal("OB Trust")
    }
  }
}

private extension OnboardingTrustView {

  func advanceIndex() async {
    await Delay(400)
    index += 1
    await Delay(800)
    index += 1
    await Delay(400)
    index += 1
    await Delay(400)
    index += 1
    await Delay(400)
    index += 1
  }

  var messagesSection: some View {
    VStack(alignment: .leading) {
      if index >= 1 {
        Text("Let's talk privacy.")
          .primaryOnboardingTextStyle()
          .transition(.blurReplace)
          .padding(.horizontal)
      }
      if index >= 2 {
        PrivacyDetailCard(
          symbol: .heartFill,
          title: "On-Device",
          detail: "I analyze your Personal Data on your device by default."
        )
        .transition(.scale)
      }
      if index >= 3 {
        BloomPlusLogo()
          .horizontallyCentered()
          .transition(.scale)
          .padding(.top)

        PrivacyDetailCard(
          symbol: .brainFill,
          title: "AI Analysis",
          detail: "If you subscribe to Bloom Plus, I’ll securely send your data to our servers only when needed for AI analysis. Your data is never used to train AI models."
        )
        .transition(.scale)
      }
      if index >= 4 {
        PrivacyDetailCard(
          symbol: .personFill,
          title: "No Personal Details",
          detail: "Your data never includes personal details like your name or email, just what's needed for analysis."
        )
        .transition(.scale)
      }
      if index >= 5 {
        PrivacyDetailCard(
          symbol: .handRaisedFill,
          title: "Data Retention",
          detail: "We only keep your data for as long as needed to create your insights, then it’s cleared automatically."
        )
        .transition(.scale)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingTrustView() { }
  }
}
