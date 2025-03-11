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

  @State private var index = 0
  @State private var didContinue = false
  @State private var presentedSheet: AnyView?

  @ObservedObject private var healthManager = HealthManager.shared

  @State private var entitlementController = EntitlementController.shared

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        DisplayAppIcon()
          .frame(width: 150)
          .transition(.blurReplace)
          .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)

        if entitlementController.hasBloomPro == false {
          Text("One last step, \(healthManager.name)!")
            .appear(with: 1, currentIndex: index)

          Text("Start on your health journey with Bloom Plus")
            .multilineTextAlignment(.center)
            .appear(with: 2, currentIndex: index)
        } else {
          Text("We made it, \(healthManager.name)!")
            .appear(with: 3, currentIndex: index)

          Text("Are you ready to get started?")
            .multilineTextAlignment(.center)
            .appear(with: 4, currentIndex: index)
        }
      }
      .horizontallyCentered()
      .onboardingTextStyle()
      .padding()
    }
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.selection, trigger: didContinue)
    .shelf {
      if entitlementController.hasBloomPro == false {
        if index >= 2 {
          Button("Check out Bloom Plus") {
            presentedSheet = BloomPlusPaywall().asAny
          }
          .buttonStyle(.onboarding)
        }
      } else {
        if index >= 4 {
          Button("Yes!") {
            didContinue.toggle()
            TelemetryDeck.signal("OB Finish")
            onContinue()
          }
          .buttonStyle(.onboarding)
        }
      }
    }
    .sheet($presentedSheet)
    .onChange(of: entitlementController.hasBloomPro) { _, _ in
      guard entitlementController.hasBloomPro == true else { return }

      Task {
        await advanceForSubscribed()
      }
    }
    .task {
      guard let hasBloomPro = entitlementController.hasBloomPro else { return }

      if !hasBloomPro {
        await advanceForPaywall()
      } else {
        await advanceForSubscribed()
      }
    }
  }
}

private extension OnboardingFinishView {

  func advanceForPaywall() async {
    while index < 2 {
      await advanceIndex()
    }
  }

  func advanceForSubscribed() async {
    index = 3
    while index < 4 {
      await advanceIndex()
    }
  }

  func advanceIndex() async {
    await Delay(1700)

    index += 1
  }
}

#Preview {
  OnboardingFinishView { }
}
