//
//  PrivacyUnknownOptInView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-29.
//

import SwiftUI

struct PrivacyUnknownOptInView: View {
  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .bottom) {
      Image(.budFridge)
        .resizable()
        .scaledToFit()
        .parallaxOverscroll()

      VStack(alignment: .leading, spacing: 10) {
        explanationSection
        aiFeatureSection
      }
      .horizontalAlignment(.leading)
      .padding(.horizontal)
      .padding(.top)
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

private extension PrivacyUnknownOptInView {

  @ViewBuilder
  var explanationSection: some View {
    Text("Bud needs your permission")
      .onboardingTextStyle()
    Text("To keep helping you with personalized health insights, I need your permission for a few things. You’re always in control.")
      .secondaryOnboardingTextStyle()
      .foregroundStyle(.secondary)
  }

  @ViewBuilder
  var aiFeatureSection: some View {
    SectionTitleView("AI Features")
      .padding(.horizontal)
    VStack {
      Toggle("Chat with Bud", isOn: .constant(true))
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    PrivacyUnknownOptInView()
  }
}
