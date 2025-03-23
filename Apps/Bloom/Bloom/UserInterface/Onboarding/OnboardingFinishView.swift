//
//  OnboardingFinishView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-31.
//

import SwiftUI
import AppUI
import TelemetryDeck

struct OnboardingFinishView: View {
  var onContinue: () -> Void

  @State private var index = 1
  @State private var didContinue = false
  @State private var presentedSheet: AnyView?

  @ObservedObject private var healthManager = HealthManager.shared

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        DisplayAppIcon()
          .frame(width: 150)
          .transition(.blurReplace)
          .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)

        Text("We made it, \(healthManager.name)!")
          .appear(with: 2, currentIndex: index)

        Text("Are you ready to get started?")
          .multilineTextAlignment(.center)
          .appear(with: 3, currentIndex: index)
      }
      .horizontallyCentered()
      .onboardingTextStyle()
      .padding()
    }
    .groupedBackground()
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.selection, trigger: didContinue)
    .shelf {
      if index >= 3 {
        Button("Yes!") {
          didContinue.toggle()
          TelemetryDeck.signal("OB Finish")
          TelemetryDeck.stopAndSendDurationSignal("Onboarding")
          onContinue()
        }
        .buttonStyle(.onboarding)
      }
    }
    .sheet($presentedSheet)
    .task {
      await advanceForSubscribed()
    }
  }
}

private extension OnboardingFinishView {

  func advanceForSubscribed() async {
    while index < 3 {
      await advanceIndex()
    }
  }

  func advanceIndex() async {
    await Delay(1000)

    index += 1
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingFinishView { }
  }
}
