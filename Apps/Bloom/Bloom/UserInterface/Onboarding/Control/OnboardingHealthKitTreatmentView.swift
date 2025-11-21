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

struct OnboardingHealthKitTreatmentView: View {
  var onContinue: () -> Void

  @State private var showMockHealthApp = false
  @State private var healthPermissionTrigger = false
  @State private var isWaitingForPermissionSheet = false
  @State private var isAuthorized = false
  @State private var didContinue = false
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
    .sensoryFeedback(.selection, trigger: didContinue)
    .shelf {
      Text("I confirm I’m the age of majority where I live and consent to Bloom’s use of my Personal Data as described.")
        .font(.caption)
        .bold()
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
        .horizontalAlignment(.leading)
        .padding(.horizontal)

      AsyncButton {
        didContinue.toggle()
        await showHealthKitPermissionView()
      } label: {
        Group {
          if isWaitingForPermissionSheet {
            CircularSpinnerView()
              .foregroundStyle(.invertedText)
          } else {
            Text("Accept and Continue")
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
      TelemetryDeck.signal("OB HealthKit v2")
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
        Task {
          await fetchHeight()
          await checkAuth()

          await MainActor.run {
            if isAuthorized {
              onContinue()
            }
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

      Text("Here's how Bloom uses your Apple Health data.")
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
        detail: "You can set goals for different health metrics, and track progress."
      )

      PrivacyDetailCard(
        symbol: .chartLineUptrendXyaxis,
        title: "Charts and Visualizations",
        detail: "Bloom can help you visualize your health data through charts, and show recommended ranges based on your age and sex."
      )

      PrivacyDetailCard(
        symbol: .squareAndArrowDownOnSquareFill,
        title: "Writing Data",
        detail: "Bloom can help facilitate writing specific types of health data, like your weight, water consumption, or what your eat."
      )
    }
  }
}

private extension OnboardingHealthKitTreatmentView {

  func recordOptIn() async throws {
    try await ConsentManager.shared.recordConsent(
      healthData: true,
      externalProcessing: nil
    )
  }

  func showHealthKitPermissionView() async {
    await checkAuth()

    if isAuthorized {
      await fetchHeight()
      onContinue()
    } else {
      isWaitingForPermissionSheet = true
      healthPermissionTrigger.toggle()
    }
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
      }
    } catch { }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingHealthKitTreatmentView { }
  }
}
