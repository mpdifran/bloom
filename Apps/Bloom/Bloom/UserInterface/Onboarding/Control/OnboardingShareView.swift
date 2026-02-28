//
//  OnboardingShareView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-02-25.
//

import SwiftUI
import AppUI
import BloomUI
import BloomFoundation
import TelemetryDeck

struct OnboardingShareView: View {
  let onContinue: () -> Void

  @State private var index = 0
  @State private var didContinueToggle = false

  private let shareURL = URL(string: "https://apps.apple.com/app/apple-store/id6739955926?pt=127532637&ct=bloom-onboarding-share&mt=8")!

  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .bottom) {
      VStack(alignment: .leading, spacing: 20) {
        BudImage(.budSuperhero, dimension: 260)
          .horizontallyCentered()

        if index >= 1 {
          Text("Stay consistent together")
            .primaryOnboardingTextStyle()
            .transition(.blurReplace)
            .padding(.horizontal)
        }
        if index >= 2 {
          Text("Share Bloom with a friend and keep each other motivated on the journey to better health!")
            .secondaryOnboardingTextStyle()
            .foregroundStyle(.secondary)
            .transition(.blurReplace)
            .padding(.horizontal)
        }
      }
      .horizontalAlignment(.leading)
      .padding()
    }
    .shelf(isVisible: index >= 2) {
      ShareLink(item: shareURL) {
        Label("Share Bloom", systemSymbol: .squareAndArrowUp)
          .horizontallyCentered()
      }
      .buttonStyle(.primary)

      Button {
        didContinueToggle.toggle()
        onContinue()
      } label: {
        Text("Skip")
          .horizontallyCentered()
      }
      .buttonStyle(.primaryAlternate)
    }
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.impact, trigger: didContinueToggle)
    .task {
      await advanceIndex()
    }
    .onAppear {
      TelemetryDeck.signal("OB Share")
    }
  }
}

private extension OnboardingShareView {

  func advanceIndex() async {
    await Delay(400)
    index += 1
    await Delay(800)
    index += 1
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingShareView { }
  }
}
