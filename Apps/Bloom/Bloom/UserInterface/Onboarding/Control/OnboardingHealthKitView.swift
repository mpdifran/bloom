//
//  OnboardingHealthKitView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import AppUI
import HealthKitUI
import Charts
import TelemetryDeck
import CoreHealth
import BloomFoundation
import BloomUI

struct OnboardingHealthKitView: View {
  let onContinue: () -> Void
  
  @State private var showMockHealthApp = false
  @State private var isWaitingForPermissionSheet = false
  @State private var healthPermissionTrigger = false
  @State private var isAuthorized = false
  @State private var didContinue = false
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        BudImage(.budCoach)

        Group {
          Text("Help me help you 💙")
          Text("Share your personal data so I can personalize your insights. Your info always stays private, I promise.")
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .onboardingTextStyle()

        if showMockHealthApp {
          MockHealthAppPermissionView()
            .horizontallyCentered()
            .transition(.move(edge: .bottom))
            .onTapGesture {
              didContinue.toggle()
              showHealthKitPermissionView()
            }
        }
      }
      .horizontalAlignment(.leading)
      .padding(.horizontal)
    }
    .groupedBackground()
    .animation(.bouncy, value: showMockHealthApp)
    .sensoryFeedback(.selection, trigger: didContinue)
    .sheet($presentedSheet)
    .shelf {
      VStack {
        Text("Your personal data always remains anonymous. Always consult with a doctor before making any changes to your health.")
          .font(.subheadline)
          .fontDesign(.rounded)
          .bold()
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        if isAuthorized {
          AsyncButton {
            didContinue.toggle()
            onContinue()
          } label: {
            Text("Let's go!")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
        } else {
          Button {
            didContinue.toggle()
            showHealthKitPermissionView()
          } label: {
            if isWaitingForPermissionSheet {
              CircularSpinnerView()
                .horizontallyCentered()
                .foregroundStyle(.invertedText)
            } else {
              Text("Continue")
                .horizontallyCentered()
            }
          }
          .buttonStyle(.primary)
        }

        HStack {
          Link(destination: .privacyPolicy) {
            Text("Privacy Policy")
              .bold()
              .frame(minHeight: 50)
          }

          Text("•")
            .bold()
            .foregroundStyle(.tint)

          Button {
            presentedSheet = OnboardingHealthKitLearnMoreView().asAny
          } label: {
            Text("Learn More")
              .bold()
              .frame(minHeight: 50)
          }
        }
      }
    }
    .task {
      await toggleMockHealthApp()
    }
    .alert(error: $error)
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
        Task {
          await fetchHeight()
          await checkAuth()
        }
      case .failure(let error):
        MainTask {
          self.error = error
        }
      }
    }
    .onAppear {
      TelemetryDeck.signal("OB HealthKit")
    }
  }
}

private extension OnboardingHealthKitView {

  func showHealthKitPermissionView() {
    isWaitingForPermissionSheet = true
    healthPermissionTrigger.toggle()
  }

  func toggleMockHealthApp() async {
    await Delay(600)

    showMockHealthApp = true
  }

  func fetchHeight() async {
    let quantity = await HealthStoreFetcher.shared.fetchLatestSample(for: .height)?.quantity
    if let height = quantity?.doubleValue(for: .meterUnit(with: .centi)) {
      HealthManager.shared.heightCM = height
    }
  }

  func checkAuth() async {
    do {
      let authStatus = try await HealthPermissionChecker.shared.checkAccessForAllTypes()

      isAuthorized = authStatus == .unnecessary

      if isAuthorized {
        await YouStatsCalculator.shared.refreshStats()
        onContinue()
      }
    } catch { }
  }
}

#Preview("Control") {
  PreviewEnvironment(variant: .control) {
    OnboardingHealthKitView { }
  }
}

#Preview("Treatment") {
  PreviewEnvironment(variant: .treatment) {
    OnboardingHealthKitView { }
  }
}
