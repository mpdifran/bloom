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
  let onContinue: () async -> Void

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
        BudImage(.budDoctor)

        Group {
          Text("I need access to your Health Data")
          Text("The more health data you share with me, the more personalized your advice will be!")
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
        Text("Your Health data always remains anonymous.")
          .font(.subheadline)
          .fontDesign(.rounded)
          .bold()
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        if isAuthorized {
          AsyncButton {
            didContinue.toggle()
            await onContinue()
          } label: {
            Text("Let's go!")
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
      TelemetryDeck.signal("AB: OB HealthKit Control")
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
        await onContinue()
      }
    } catch { }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingHealthKitView { 
      // Async preview action
    }
  }
}
