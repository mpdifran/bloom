//
//  HealthDataConsentView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-10.
//

import SwiftUI
import AppUI
import BloomUI
import CoreHealth

struct HealthDataConsentView: View {
  var onContinue: () -> Void

  @State private var healthDataCloudOptIn = false
  @State private var healthPermissionTrigger = false
  @State private var isWaitingForPermissionSheet = false
  @State private var isAuthorized = false
  @State private var error: Error?

  var body: some View {
    NavigationStack {
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
            cloudSection
          }
          .padding(.horizontal)
          .padding(.top, 160)
        }
      }
      .removeScrollEdgeEffect(shouldHide: true)
      .ignoresSafeArea(.all, edges: .top)
      .navigationBarTitleDisplayMode(.inline)
      .shelf {
        Text("By continuing, I confirm I’m the age of majority where I live and consent to Bloom’s use of my personal health data as described.")
          .font(.caption)
          .bold()
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
          .horizontalAlignment(.leading)
          .padding(.horizontal)

        AsyncButton {
          await recordOptIn()
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
}

private extension HealthDataConsentView {

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

      Text("Bloom uses your Apple Health data to provide personalized insights and help you track goals. You are in full control of what data you would like to share.")
        .font(.body)
        .multilineTextAlignment(.leading)
    }
    .fixedSize(horizontal: false, vertical: true)
  }

  @ViewBuilder
  var cloudSection: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Share Data Externally")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .bold()

//        Text("OPTIONAL")
//          .font(.system(size: 10))
//          .fontWeight(.heavy)
//          .padding(2)
//          .padding(.horizontal, 6)
//          .background {
//            Capsule()
//              .fill(.mutedBlue)
//          }
      }
      .padding(.horizontal)

      Toggle("Bud Insights", isOn: $healthDataCloudOptIn)
        .fixedSize(horizontal: false, vertical: true)
        .bold()
        .cardContainer()

      Text("""
          Features like Chat with Bud, Today Insights, and Biological Age send limited, summarized data to Bloom’s servers for processing. Your health data is never stored on our servers.
          """)
      .bold()
      .foregroundStyle(.secondary)
      .font(.caption)
      .padding(.horizontal)
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}

private extension HealthDataConsentView {

  func recordOptIn() async {
    // TODO: Send request to backend to make acceptance
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
    HealthDataConsentView() { }
  }
}
