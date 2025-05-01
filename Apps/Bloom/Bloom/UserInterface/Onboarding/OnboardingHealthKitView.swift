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
      VStack(alignment: .leading, spacing: 20) {
        Group {
          Text("Let's calculate your Vitals!")
            .padding(.top, 30)
          Text("Bloom needs access to your Health data in order give you guidance on your health.")
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        .onboardingTextStyle()

        if showMockHealthApp {
          MockHealthAppPermissionView()
            .padding(.top, 40)
            .horizontallyCentered()
            .transition(.move(edge: .bottom))
            .onTapGesture {
              didContinue.toggle()
              showHealthKitPermissionView()
            }
        }
      }
      .horizontalAlignment(.leading)
      .padding()
    }
    .groupedBackground()
    .animation(.bouncy, value: showMockHealthApp)
    .sensoryFeedback(.selection, trigger: didContinue)
    .sheet($presentedSheet)
    .shelf {
      VStack {
        Text("Your Health data always remains anonymous.")
          .font(.subheadline)
          .fontDesign(.rounded)
          .bold()
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        if isAuthorized {
          Button("Let's go!") {
            didContinue.toggle()
            onContinue()
          }
          .buttonStyle(.onboarding)
        } else {
          Button {
            didContinue.toggle()
            showHealthKitPermissionView()
          } label: {
            if isWaitingForPermissionSheet {
              CircularSpinnerView()
                .foregroundStyle(.invertedText)
            } else {
              Text("Continue")
            }
          }
          .buttonStyle(.onboarding)
        }

        Link(destination: .privacyPolicy) {
          Text("Privacy Policy")
            .bold()
            .frame(minHeight: 50)
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
        await VitalsCalculator.shared.forceFetchVitals()
        onContinue()
      }
    } catch { }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingHealthKitView { }
  }
}
