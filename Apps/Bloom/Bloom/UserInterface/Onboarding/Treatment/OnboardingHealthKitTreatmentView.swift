//
//  OnboardingHealthKitTreatmentView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-13.
//

import SwiftUI
import AppUI
import BloomUI
import CoreHealth
import BloomFoundation
import SFSafeSymbols
import TelemetryDeck
import AppFoundations

struct OnboardingHealthKitTreatmentView: View {
  let focus: PersonalizationFocus?
  var onContinue: () async -> Void

  @State private var healthPermissionTrigger = false
  @State private var isWaitingForPermissionSheet = false
  @State private var hasShownPermissionSheet = false
  @State private var didContinue = false
  @State private var index = 0
  @State private var error: Error?

  var body: some View {
    BloomScrollView(padding: .bottom) {
      ZStack {
        Image(.afternoonScenery)
          .resizable()
          .scaledToFit()
          .parallaxOverscroll()
          .zStackAlignment(.top)


        VStack(spacing: 20) {
          BudImage(.budHealthApp, dimension: 200)
          explanationSection

          detailsSection
        }
        .padding(.horizontal)
        .padding(.top, 160)
      }
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.impact, trigger: didContinue)
    .shelf(isVisible: index >= 5) {
      Text("I confirm I’m the age of majority where I live and consent to Bloom reading and writing my Health app data for the purposes described above.")
        .font(.caption)
        .bold()
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .horizontallyCentered()
        .padding(.horizontal)

      AsyncButton {
        didContinue.toggle()
        if hasShownPermissionSheet {
          await onContinue()
        } else {
          await recordOptIn()
          hasShownPermissionSheet = true
          isWaitingForPermissionSheet = true
          healthPermissionTrigger.toggle()
        }
      } label: {
        Group {
          if isWaitingForPermissionSheet {
            CircularSpinnerView()
              .foregroundStyle(.invertedText)
          } else {
            Text("Continue")
          }
        }
        .horizontallyCentered()
      }
      .buttonStyle(.primary)

      privacyEmailView
    }
    .alert(error: $error)
    .task {
      await advanceIndex()
    }
    .onAppear {
      TelemetryDeck.signal("OB HealthKit")
    }
    .healthDataAccessRequest(
      store: HealthPermissionChecker.shared.healthStore,
      shareTypes: HealthPermissionChecker.shared.writeTypes(),
      readTypes: HealthPermissionChecker.shared.readTypes(),
      trigger: healthPermissionTrigger
    ) { result in

      MainTask {
        isWaitingForPermissionSheet = false
      }

      switch result {
      case .success:
        break
      case .failure(let error):
        MainTask {
          self.error = error
        }
      }
    }
  }
}

extension OnboardingHealthKitTreatmentView {

  func advanceIndex() async {
    await Delay(800)
    index += 1
    await Delay(1000)
    index += 1
    await Delay(300)
    index += 1
    await Delay(300)
    index += 1
    await Delay(500)
    withAnimation {
      index += 1
    }
  }

  var privacyEmailView: some View {
    HStack {
      Link("Privacy Policy", destination: .privacyPolicy)
        .bold()
        .frame(height: 40)
        .horizontallyCentered()

      Link("Questions? Email Us!", destination: .emailBloom(subject: "Privacy Questions"))
        .bold()
        .frame(height: 40)
        .horizontallyCentered()
    }
    .font(.subheadline)
  }

  @ViewBuilder
  var explanationSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      if index >= 1 {
        HStack {
          Image(.healthAppIcon)
            .resizable()
            .frame(square: 40)
          Text("Your Data, Your Choice")
            .primaryOnboardingTextStyle()
          Spacer()
        }

        Text(explanationText)
          .secondaryOnboardingTextStyle()
          .multilineTextAlignment(.leading)
      }
    }
    .fixedSize(horizontal: false, vertical: true)
  }

  var detailsSection: some View {
    VStack {
      if index >= 2 {
        PrivacyDetailCard(
          symbol: .trophyFill,
          title: "Set and Track Goals",
          detail: "Set goals for the metrics you care about and stay on track over time."
        )
      }

      if index >= 3 {
        PrivacyDetailCard(
          symbol: .chartLineUptrendXyaxis,
          title: "Charts and Visualizations",
          detail: "I’ll help you visualize your health trends and show typical ranges for context."
        )
      }

      if index >= 4 {
        PrivacyDetailCard(
          symbol: .squareAndArrowDownOnSquareFill,
          title: "Writing Data",
          detail: "Bloom can help record things like weight, hydration, or what you eat."
        )
      }
    }
  }
}

private extension OnboardingHealthKitTreatmentView {

  var explanationText: String {
    switch focus {
    case .boostEnergyLevels:
      return String(
        localized: "Here's how I'll use your data to spot patterns that affect your daily energy and help you feel more energized.",
        comment: "Intro on the onboarding Health permission screen, tailored to the focus the user picked."
      )
    case .buildHealthyHabits:
      return String(
        localized: "Here's how I’ll use your data to help you build healthy habits and stay consistent over time.",
        comment: "Intro on the onboarding Health permission screen, tailored to the focus the user picked."
      )
    case .improveBodyComposition:
      return String(
        localized: "Here's how I’ll use your data to help you understand the signals that influence body composition.",
        comment: "Intro on the onboarding Health permission screen, tailored to the focus the user picked."
      )
    case .improveSleep:
      return String(
        localized: "Here's how I’ll use your data to help you understand what’s affecting your sleep.",
        comment: "Intro on the onboarding Health permission screen, tailored to the focus the user picked."
      )
    case .reduceStress:
      return String(
        localized: "Here's how I’ll use your data to help you understand what’s impacting your stress levels.",
        comment: "Intro on the onboarding Health permission screen, tailored to the focus the user picked."
      )
    case .understandHealthData:
      return String(
        localized: "Here's how I’ll help you make sense of your health data and show you what it all means.",
        comment: "Intro on the onboarding Health permission screen, tailored to the focus the user picked."
      )
    default:
      return String(
        localized: "Here's how I'll use your data to give you personalized insights about your sleep, activity, stress, and overall wellness.",
        comment: "Intro on the onboarding Health permission screen, tailored to the focus the user picked."
      )
    }
  }
}

private extension OnboardingHealthKitTreatmentView {

  func recordOptIn() async {
    await ConsentManager.shared.recordConsent(
      healthData: true,
      healthDataConsentScreenVersion: "OnboardingHealthKitView.v1"
    )
    ConsentManager.shared.markConsentAsChecked()
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingHealthKitTreatmentView(focus: .improveSleep) { }
  }
}
