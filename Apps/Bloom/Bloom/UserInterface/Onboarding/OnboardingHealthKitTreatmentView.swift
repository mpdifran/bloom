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
          BudImage(.budCoach, dimension: 180)
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
      Text("By continuing, I confirm I’m the age of majority where I live and consent to Bloom’s use of my personal health data as described.")
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
          .font(.title)
          .bold()
          .fontDesign(.rounded)
        Spacer()
      }

      Text("Bloom uses your Apple Health data to provide personalized insights and help you track goals.")
        .font(.body)
        .multilineTextAlignment(.leading)
    }
    .fixedSize(horizontal: false, vertical: true)
  }

  var detailsSection: some View {
    VStack {
      PrivacyDetailCard(
        symbol: .iphone,
        title: "Stays On Device",
        detail: "Health access allows Bloom to display health data on your device."
      )

      PrivacyDetailCard(
        symbol: .figure,
        title: "Personalized Insights",
        detail: "The more health data you share, the more personalized your insights will be."
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

private struct PrivacyDetailCard: View {

  let symbol: SFSymbol
  let title: String
  let detail: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemSymbol: symbol)
          .font(.title3)
          .foregroundStyle(.tint)
          .frame(square: 30)
          .padding(6)
          .background {
            RoundedRectangle(cornerRadius: 13)
              .fill(.white)
          }

        Text(title)
          .font(.title3)
          .fontDesign(.rounded)
          .bold()
      }

      Text(detail)
        .font(.body)
        .fontDesign(.rounded)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .horizontalAlignment(.leading)
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingHealthKitTreatmentView { }
  }
}
