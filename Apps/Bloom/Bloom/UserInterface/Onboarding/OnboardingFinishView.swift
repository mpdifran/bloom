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

struct OnboardingFinishView: View {
  var onContinue: () -> Void

  @State private var index = 1
  @State private var didContinue = false
  @State private var presentedSheet: AnyView?

  @ObservedObject private var healthManager = HealthManager.shared
  @Environment(ThemeController.self) private var themeController

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        BudImage(.budTrophy, dimension: 200)
          .transition(.blurReplace)
          .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)
          .standardConfetti($index, colors: [themeController.theme.color, .white])

        Text("You made it, \(usersName)!")
          .appear(with: 2, currentIndex: index, secondaryIfNotCurrentIndex: false)

        Text("Are you ready to get started?")
          .multilineTextAlignment(.center)
          .appear(with: 3, currentIndex: index, secondaryIfNotCurrentIndex: false)
      }
      .horizontallyCentered()
      .onboardingTextStyle()
      .padding()
    }
    .groupedBackground()
    .animation(.default, value: index)
    .sensoryFeedback(.impact, trigger: index)
    .sensoryFeedback(.selection, trigger: didContinue)
    .shelf {
      if index >= 3 {
        Button("Let's Go!") {
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

  var usersName: String {
    let trimmedName = healthManager.name.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedName.isEmpty ? "Friend" : trimmedName
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
