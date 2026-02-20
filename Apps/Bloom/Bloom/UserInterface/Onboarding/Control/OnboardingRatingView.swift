//
//  OnboardingRatingView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-02-20.
//

import SwiftUI
import StoreKit
import AppUI
import BloomUI
import BloomFoundation
import TelemetryDeck

struct OnboardingRatingView: View {
  let onContinue: () -> Void

  @State private var index = 0
  @State private var hasRated = false
  @State private var didContinueToggle = false

  @Environment(\.requestReview) private var requestReview
  @Environment(\.openURL) private var openURL

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
          BudImage(.budTrophy, dimension: 260)
            .horizontallyCentered()
          messagesSection
        }
        .horizontalAlignment(.leading)
        .padding(.top, 100)
        .padding(.horizontal)
      }
    }
    .shelf {
      shelfContent
    }
    .animation(.default, value: index)
    .animation(.default, value: hasRated)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.impact, trigger: didContinueToggle)
    .sensoryFeedback(.impact, trigger: hasRated)
    .task {
      await advanceIndex()
    }
    .onAppear {
      TelemetryDeck.signal("OB Rating")
    }
  }
}

private extension OnboardingRatingView {

  func advanceIndex() async {
    await Delay(400)
    index += 1
    await Delay(800)
    index += 1
    for _ in 0..<5 {
      await Delay(200)
      index += 1
    }
  }

  var messagesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      if index >= 1 {
        Text("Enjoying Bloom?")
          .primaryOnboardingTextStyle()
          .transition(.blurReplace)
          .padding(.horizontal)
      }
      if index >= 2 {
        Text("If you're liking the experience so far, a quick rating would mean a lot to our small but mighty team!")
          .secondaryOnboardingTextStyle()
          .foregroundStyle(.secondary)
          .transition(.blurReplace)
          .padding(.horizontal)
      }
      HStack(spacing: 8) {
        ForEach(0..<5, id: \.self) { starIndex in
          if index >= 3 + starIndex {
            Image(systemSymbol: .starFill)
              .font(.title)
              .foregroundStyle(.mutedOrange)
              .transition(.scale.combined(with: .opacity))
          }
        }
      }
      .horizontallyCentered()
      .onTapGesture {
        requestReview()
      }
      .padding(.top, 8)
    }
  }

  @ViewBuilder
  var shelfContent: some View {
    if hasRated {
      Button {
        openURL(.writeReview)
      } label: {
        Text("Really Like Us? Leave a Review!")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .transition(.blurReplace)

      Button {
        didContinueToggle.toggle()
        onContinue()
      } label: {
        Text("Continue")
          .horizontallyCentered()
      }
      .buttonStyle(.primaryAlternate)
      .transition(.blurReplace)
    } else {
      Button {
        requestReview()
        withAnimation {
          hasRated = true
        }
      } label: {
        Label("Rate Bloom", systemSymbol: .starFill)
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .transition(.blurReplace)

      Button {
        didContinueToggle.toggle()
        onContinue()
      } label: {
        Text("Skip")
          .horizontallyCentered()
      }
      .buttonStyle(.primaryAlternate)
      .transition(.blurReplace)
    }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingRatingView() { }
  }
}
