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

struct OnboardingHealthKitView: View {
    let onContinue: () -> Void

    @State private var showMockHealthApp = false
    @State private var healthPermissionTrigger = false
    @State private var isAuthorized = false
    @State private var error: Error?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("Let's calculate your Vitals!")
                    .padding(.top, 30)
                Text("Bloom needs access to your Health data in order to set personalized goals.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .font(.title)
            .bold()
            .fontDesign(.rounded)

            Spacer()
        }
        .overlay {
            if showMockHealthApp {
                MockHealthAppPermissionView()
                    .zStackAlignment(.bottom)
                    .offset(y: 180)
                    .horizontallyCentered()
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.bouncy, value: showMockHealthApp)
        .horizontalAlignment(.leading)
        .padding()
        .shelf {
            VStack {
                Text("Your Health data never leaves your device")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if isAuthorized {
                    Button("Let's Go!") {
                        onContinue()
                    }
                    .buttonStyle(.onboarding)
                } else {
                    Button("Connect to Health", systemImage: "heart.fill") {
                        healthPermissionTrigger.toggle()
                    }
                    .buttonStyle(.onboarding)
                }
//                Text("Bloom is not a substitute for professional medical advice. Always consult your physician first.")
//                    .multilineTextAlignment(.center)
//                    .foregroundStyle(.secondary)
//                    .font(.caption)
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
            switch result {
            case .success:
                Task { await checkAuth() }
            case .failure(let error):
                MainTask {
                    self.error = error
                }
            }
        }
    }
}

private extension OnboardingHealthKitView {

    func toggleMockHealthApp() async {
        await Delay(600)

        showMockHealthApp = true
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
    OnboardingHealthKitView { }
}
