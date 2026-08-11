//
//  OnboardingWelcomeView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import AppUI
import TelemetryDeck
import CoreHealth
import BloomFoundation
import BloomUI

struct OnboardingWelcomeView: View {
  var onContinue: () -> Void

  @State private var index = 0
  @State private var didContinue = false
  @FocusState private var isFocused: Bool

  @ObservedObject private var healthManager = HealthManager.shared

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        newWelcomeContent
      }
      .padding()
      .horizontalAlignment(.leading)
    }
    .groupedBackground()
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.selection, trigger: didContinue)
    .animation(.bouncy, value: index)
    .shelf {
      if(index >= 4) {
        if isFocused {
          Button {
            isFocused = false
          } label: {
            Text("Done")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
        } else {
          Button {
            didContinue.toggle()
            onContinue()
          } label: {
            Text("Looks good!")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
        }
      }
    }
    .task {
      while index < 4 {
        await advanceIndex()
      }
    }
    .onAppear {
      TelemetryDeck.signal("OB Welcome")
      TelemetryDeck.startDurationSignal("Onboarding")
    }
  }
}

private extension OnboardingWelcomeView {

  @ViewBuilder
  var newWelcomeContent: some View {
    Text("Hello there! Welcome to Bloom.")
      .transition(.opacity)
      .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)
      .onboardingTextStyle()

    Text("Let's get to know each other a bit...")
      .transition(.opacity)
      .appear(with: 2, currentIndex: index, secondaryIfNotCurrentIndex: false)
      .onboardingTextStyle()

    EditUserProfileCardView()
      .focused($isFocused)
      .transition(.blurReplace)
      .appear(with: 3, currentIndex: index, secondaryIfNotCurrentIndex: false)
      .onAppear {
        isFocused = true
      }
  }
}

private extension OnboardingWelcomeView {

  func didSubmitName() {
    guard healthManager.name.isNotEmpty else { return }

    isFocused = false
    withAnimation {
      index += 1
    }
  }

  func advanceIndex() async {
    await Delay(1000)

    withAnimation {
      index += 1
    }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingWelcomeView { }
  }
}
