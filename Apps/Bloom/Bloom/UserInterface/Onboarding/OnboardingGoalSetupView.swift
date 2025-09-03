//
//  OnboardingGoalSetupView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-24.
//

import SwiftUI
import AppUI
import TelemetryDeck

struct OnboardingGoalSetupView: View {
  let onContinue: () -> Void

  @State private var index = 1
  @State private var didContinue = false
  @State private var error: Error?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        BudImage(.budStrengthTraining)

        Group {
          Text("Let's set some goals!")
            .transition(.opacity)
            .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)

          Text("Goals are a great way to help improve specific aspects of your health, and keep track of the progress.")
            .font(.title3)
            .foregroundStyle(.secondary)
            .transition(.opacity)
            .appear(with: 2, currentIndex: index)

          // TODO: This is incomplete
        }
        .onboardingTextStyle()
      }
      .horizontalAlignment(.leading)
      .padding()
    }
    .alert(error: $error)
    .groupedBackground()
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.selection, trigger: didContinue)
    .task {
      while index < 2 {
        await advanceIndex()
      }
    }
    .onAppear {
      TelemetryDeck.signal("OB Goal Setup")
    }
  }
}

private extension OnboardingGoalSetupView {

  func advanceIndex() async {
    await Delay(1000)

    index += 1
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingGoalSetupView() { }
  }
}
