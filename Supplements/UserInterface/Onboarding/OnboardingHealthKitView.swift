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

    @State private var healthPermissionTrigger = false
    @State private var isAuthorized = false
    @State private var error: Error?

    var body: some View {
        OnboardingCardTemplateView {
            Image(systemName: "hand.raised.circle.fill")
                .foregroundStyle(.white, .tint)
                .font(.system(size: 80))

            Text("Privacy")
                .font(.largeTitle)
                .bold()

            Text("We value and respect your privacy.")
                .padding(.top)
        } bottom: {
            VStack(spacing: 20) {
                Spacer()
                Text("Bloom uses data in the Health App to give you recommendations on how to improve your health.")
                Text("Your data is always private and only you will have access to it.")
                    .bold()
                Spacer()
            }
            .frame(maxWidth: 300)
            .multilineTextAlignment(.center)
            .horizontallyCentered()
        }
        .shelf {
            VStack {
                if isAuthorized {
                    ProminentButton("Continue") {
                        onContinue()
                    }
                } else {
                    ProminentButton("Connect to Health", systemImage: "heart.fill") {
                        healthPermissionTrigger.toggle()
                    }
                }
//                Text("Bloom is not a substitute for professional medical advice. Always consult your physician first.")
//                    .multilineTextAlignment(.center)
//                    .foregroundStyle(.secondary)
//                    .font(.caption)
            }
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
                self.error = error
            }
        }
    }
}

private extension OnboardingHealthKitView {

    func checkAuth() async {
        do {
            let authStatus = try await HealthPermissionChecker.shared.checkAccessForAllTypes()

            isAuthorized = authStatus == .unnecessary

            if isAuthorized {
                onContinue()
            }
        } catch { }
    }
}

#Preview {
    OnboardingHealthKitView { }
}
