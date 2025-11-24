//
//  OnboardingFinishView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-31.
//

import SwiftUI
import AppUI
import TelemetryDeck
import CoreHealth
import BloomFoundation
import BloomUI

struct OnboardingFinishView: View {
  var onContinue: () -> Void

  @State private var index = 1
  @State private var didContinue = false
  @State private var presentedSheet: AnyView?
  @State private var presentedPaywall: AnyView?

  @ObservedObject private var healthManager = HealthManager.shared
  @Environment(ThemeController.self) private var themeController

  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .bottom) {
      ZStack {
        Image(.morningScenery)
          .resizable()
          .scaledToFit()
          .parallaxOverscroll()
          .zStackAlignment(.top)

        VStack(spacing: 20) {
          BudImage(.budTrophy, dimension: 260)
            .transition(.blurReplace)
            .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)
            .standardConfetti($index, colors: [themeController.theme.color, .white])

          Text("You made it, \(usersName)!")
            .appear(with: 2, currentIndex: index, secondaryIfNotCurrentIndex: false)

          Text("Are you ready to get started?")
            .multilineTextAlignment(.center)
            .appear(with: 3, currentIndex: index, secondaryIfNotCurrentIndex: false)
        }
        .onboardingTextStyle()
        .padding(.top, 100)
        .padding(.horizontal)
      }
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .animation(.default, value: index)
    .sensoryFeedback(.success, trigger: index)
    .sensoryFeedback(.impact, trigger: didContinue)
    .shelf {
      if index >= 3 {
        AsyncButton {
          await performFinish()
        } label: {
          Text("Let's Go!")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      }
    }
    .sheet($presentedSheet)
    .fullScreenCover($presentedPaywall)
    .task {
      await advanceForSubscribed()
    }
  }
}

private extension OnboardingFinishView {

  func performFinish() async {
    didContinue.toggle()
    TelemetryDeck.signal("OB Finish")
    TelemetryDeck.stopAndSendDurationSignal("Onboarding")
    TelemetryDeck.stopAndSendDurationSignal("Onboarding V2")

    // Cancel re-engagement notifications since onboarding is complete
    await ReEngagementScheduler.shared.cancelNotification()

    // Show paywall after onboarding
    presentedPaywall = BloomPlusPaywall(
      focus: .standard,
      onPurchase: {
        // Called on purchase after dismiss
      },
      onDismiss: {
        // Called when paywall dismisses for any reason
        onContinue()
      }
    ).asAny
  }

  var usersName: String {
    let trimmedName = healthManager.name.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedName.isEmpty ? "friend" : trimmedName
  }

  func advanceForSubscribed() async {
    while index < 5 {
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
