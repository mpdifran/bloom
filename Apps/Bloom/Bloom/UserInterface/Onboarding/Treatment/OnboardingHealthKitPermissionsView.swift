//
//  OnboardingHealthKitPermissionsView.swift
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

struct OnboardingHealthKitPermissionsView: View {
  let focus: PersonalizationFocus?
  let onContinue: () -> Void

  @State private var index = 0

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
          BudImage(.budHealthApp, dimension: 200)
            .horizontallyCentered()

          explanationSection
        }
        .horizontalAlignment(.leading)
        .padding(.top, 100)
      }
    }
    .shelf(isVisible: index >= 4) {
      Button {

      } label: {
        Text("Connect to Apple Health")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .animation(.default, value: index)
    .sensoryFeedback(.impact, trigger: index)
    .task {
      await advanceIndex()
    }
  }
}

private extension OnboardingHealthKitPermissionsView {

  func advanceIndex() async {
    await Delay(500)
    index += 1
    await Delay(800)
    index += 1
    await Delay(800)
    index += 1
    await Delay(800)
    index += 1
  }

  @ViewBuilder
  var explanationSection: some View {
    if index >= 1 {
      ChatBubble(
        position: .leading,
        showTail: true,
        backgroundStyle: .background
      ) {
        Text("To help you stay focused on your health, I need access to your Apple Health data.")
          .secondaryOnboardingTextStyle()
          .fixedSize(horizontal: false, vertical: true)
      }
      .transition(.move(edge: .leading))
    }

    if index >= 2 {
      ChatBubble(
        position: .leading,
        showTail: true,
        backgroundStyle: .background
      ) {
        Text(explanationText)
          .secondaryOnboardingTextStyle()
          .fixedSize(horizontal: false, vertical: true)
      }
      .transition(.move(edge: .leading))
    }

    if index >= 3 {
      ChatBubble(
        position: .leading,
        showTail: true,
        backgroundStyle: .background
      ) {
        Text("You're always in control — you choose what to share.")
          .secondaryOnboardingTextStyle()
          .fixedSize(horizontal: false, vertical: true)
      }
      .transition(.move(edge: .leading))
    }
  }
}

private extension OnboardingHealthKitPermissionsView {

  var explanationText: String {
    switch focus {
    case .boostEnergyLevels:
      "I’ll use your data to spot patterns that affect your daily energy and help you feel more energized."
    case .buildHealthyHabits:
      "I’ll use your data to help you build healthy habits and stay consistent over time."
    case .improveBodyComposition:
      "I’ll use your data to help you understand the signals that influence body composition."
    case .improveSleep:
      "I’ll use your data to help you understand what’s affecting your sleep."
    case .reduceStress:
      "I’ll use your data to help you understand what’s impacting your stress levels."
    case .understandHealthData:
      "I’ll help you make sense of your health data and show you what it all means."
    default:
      "I use your data to give you personalized insights about your sleep, activity, stress, and overall wellness."
    }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingHealthKitPermissionsView(focus: .improveSleep) { }
  }
}
