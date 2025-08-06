//
//  OnboardingHealthKitViewTreatement.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-05.
//

import SwiftUI
import AppUI
import TelemetryDeck
import CoreHealth

struct OnboardingHealthKitViewTreatement: View {
  let onContinue: () async -> Void

  @State private var isWaitingForPermissionSheet = false
  @State private var healthPermissionTrigger = false
  @State private var isAuthorized = false
  @State private var didContinue = false
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        appIconsHeader
        textSection
        learnMoreButton
      }
      .padding(.top, 100)
      .padding()
      .horizontallyCentered()
    }
    .groupedBackground()
    .sensoryFeedback(.selection, trigger: didContinue)
    .shelf {
      Text("Health data secured by \(Image(systemSymbol: .appleLogo)) Apple")
        .foregroundStyle(.secondary)
        .font(.subheadline)
        .bold()

      if isAuthorized {
        AsyncButton {
          didContinue.toggle()
          await onContinue()
        } label: {
          Text("Let's go!")
        }
        .buttonStyle(.onboarding)
      } else {
        AsyncButton {
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
    }
    .alert(error: $error)
    .sheet($presentedSheet)
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
      TelemetryDeck.signal("AB: OB HealthKit Treatment")
    }
  }
}

private extension OnboardingHealthKitViewTreatement {

  var appIconsHeader: some View {
    ZStack {
      DisplayAppIcon()
        .frame(square: 80)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .rotationEffect(.degrees(5))
        .offset(x: 35)

      Image(.healthAppIcon)
        .resizable()
        .frame(square: 94)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .rotationEffect(.degrees(-5))
        .offset(x: -35)
    }
  }

  @ViewBuilder
  var textSection: some View {
    VStack(spacing: 16) {
      Text("Connect Bloom with Apple Health")
        .onboardingTextStyle()

      Text("This will let us give you health insights and personalized advice.")
        .font(.body)
        .foregroundStyle(.secondary)
    }
    .fixedSize(horizontal: false, vertical: true)
    .multilineTextAlignment(.center)
  }

  var learnMoreButton: some View {
    Button {
      presentedSheet = OnboardingHealthKitLearnMoreView().asAny
    } label: {
      Label("Learn More", systemSymbol: .infoCircle)
        .bold()
    }
    .frame(height: 35)
  }
}

private extension OnboardingHealthKitViewTreatement {

  func showHealthKitPermissionView() {
    isWaitingForPermissionSheet = true
    healthPermissionTrigger.toggle()
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
    OnboardingHealthKitViewTreatement {

    }
  }
}
