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

  @State private var showMockHealthApp = false
  @State private var healthPermissionTrigger = false
  @State private var isWaitingForPermissionSheet = false
  @State private var isAuthorized = false
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

//          if showMockHealthApp {
//            MockHealthAppPermissionView()
//              .horizontallyCentered()
//              .transition(.move(edge: .bottom))
//              .onTapGesture {
//                didContinue.toggle()
//                Task {
//                  await showHealthKitPermissionView()
//                }
//              }
//              .padding(.bottom, -200)
//          }
        }
        .padding(.horizontal)
        .padding(.top, 160)
      }
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .animation(.bouncy, value: showMockHealthApp)
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: didContinue)
    .shelf {
      Text("I confirm I’m the age of majority where I live and consent to Bloom using my data as described above.")
        .font(.caption)
        .bold()
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
        .horizontalAlignment(.leading)
        .padding(.horizontal)

      AsyncButton {
        didContinue.toggle()
        do {
          try await recordOptIn()
        } catch {
          self.error = error
          return
        }
        await showHealthKitPermissionView()
      } label: {
        Group {
          if isWaitingForPermissionSheet {
            CircularSpinnerView()
              .foregroundStyle(.invertedText)
          } else {
            Text("Agree and Continue")
          }
        }
        .horizontallyCentered()
      }
      .buttonStyle(.primary)

      privacyEmailView
    }
    .alert(error: $error)
    .task {
      await Delay(600)
      showMockHealthApp = true
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
        Task { @MainActor in
          await checkAuth()

          if isAuthorized {
            await onContinue()
          }
        }
      case .failure(let error):
        MainTask {
          self.error = error
        }
      }
    }
  }
}

extension OnboardingHealthKitTreatmentView {

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
    .fixedSize(horizontal: false, vertical: true)
  }

  var detailsSection: some View {
    VStack {
      PrivacyDetailCard(
        symbol: .trophyFill,
        title: "Set and Track Goals",
        detail: "Set goals for the metrics you care about and stay on track over time."
      )

      PrivacyDetailCard(
        symbol: .chartLineUptrendXyaxis,
        title: "Charts and Visualizations",
        detail: "I’ll help you visualize your health trends and show typical ranges for context."
      )

      PrivacyDetailCard(
        symbol: .squareAndArrowDownOnSquareFill,
        title: "Writing Data",
        detail: "Bloom can help record things like weight, hydration, or what you eat."
      )
    }
  }
}

private extension OnboardingHealthKitTreatmentView {

  var explanationText: String {
    switch focus {
    case .boostEnergyLevels:
      "Here's how I'll use your data to spot patterns that affect your daily energy and help you feel more energized."
    case .buildHealthyHabits:
      "Here's how I’ll use your data to help you build healthy habits and stay consistent over time."
    case .improveBodyComposition:
      "Here's how I’ll use your data to help you understand the signals that influence body composition."
    case .improveSleep:
      "Here's how I’ll use your data to help you understand what’s affecting your sleep."
    case .reduceStress:
      "Here's how I’ll use your data to help you understand what’s impacting your stress levels."
    case .understandHealthData:
      "Here's how I’ll help you make sense of your health data and show you what it all means."
    default:
      "Here's how I'll use your data to give you personalized insights about your sleep, activity, stress, and overall wellness."
    }
  }
}

private extension OnboardingHealthKitTreatmentView {

  func recordOptIn() async throws {
    do {
      try await ConsentManager.shared.recordConsent(
        healthData: true,
        externalProcessing: nil
      )
    } catch {
      TelemetryDeck.errorOccurred(
        id: "OnboardingHealthKitTreatmentView.recordOptIn",
        category: .thrownException,
        message: error.localizedDescription
      )
      throw NSError(description: "There was a problem recording your consent. Please try again.")
    }
  }

  func showHealthKitPermissionView() async {
    await checkAuth()

    if isAuthorized {
      await onContinue()
    } else {
      isWaitingForPermissionSheet = true
      healthPermissionTrigger.toggle()
    }
  }

  func checkAuth() async {
    do {
      let authStatus = try await HealthPermissionChecker.shared.checkAccessForAllTypes()

      isAuthorized = authStatus == .unnecessary

      if isAuthorized {
        await VitalsCalculator.shared.forceFetchVitals()
      }
    } catch { }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingHealthKitTreatmentView(focus: .improveSleep) { }
  }
}
