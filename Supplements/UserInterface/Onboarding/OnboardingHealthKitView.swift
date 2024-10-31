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

struct OnboardingHealthKitView: View {
    let onContinue: () -> Void

    @State private var showMockHealthApp = false
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
                    Text("Bloom needs access to your Health data in order to set personalized goals.")
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
                            presentedSheet = OnboardingHealthKitPrivacyCard {
                                healthPermissionTrigger.toggle()
                            }.asAny
                        }
                }
            }
            .padding()
        }
        .animation(.bouncy, value: showMockHealthApp)
        .sensoryFeedback(.selection, trigger: didContinue)
        .horizontalAlignment(.leading)
        .sheet($presentedSheet)
        .shelf {
            VStack {
                Text("Your Health data never leaves your device")
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
                    Button("Continue") {
                        didContinue.toggle()
                        presentedSheet = OnboardingHealthKitPrivacyCard {
                            healthPermissionTrigger.toggle()
                        }.asAny
                    }
                    .buttonStyle(.onboarding)
                }
//                Text("Bloom is not a substitute for professional medical advice. Always consult your physician first.")
//                    .multilineTextAlignment(.center)
//                    .foregroundStyle(.secondary)
//                    .font(.caption)
//                    .fontDesign(.rounded)
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
        .onAppear {
            TelemetryDeck.signal("OB HealthKit")
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
