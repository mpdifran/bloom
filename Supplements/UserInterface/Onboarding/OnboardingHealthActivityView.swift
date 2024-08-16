//
//  OnboardingHealthActivityView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI
import AppUI
import HealthKitUI

struct OnboardingHealthActivityView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

    @State private var isAuthorized = false
    @State private var triggerHealthPermissionSheet = false
    @State private var showCards = false
    @State private var basalEnergy: Double = 0
    @State private var activeEnergy: Double = 0
    @State private var error: Error?

    var body: some View {
        OnboardingCardTemplateView {
            HealthPrivacyCardView(
                title: "Activity Data",
                message: "Bloom can use your activity data to help you live a healthier life."
            )
        } bottom: {
            ScrollView {
                VStack {
                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .activityLevel,
                            subtitle: "\(basalEnergy.format()) Cal Basal\n\(activeEnergy.format()) Cal Active",
                            status: basalEnergy > 0 ? "Light" : "No Data",
                            score: 0.9,
                            color: basalEnergy > 0 ? .green : .gray,
                            trend: basalEnergy > 0 ? .increasing : .noTrend
                        )
                    )
                    .contentTransition(.numericText(value: basalEnergy))
                    .opacity(showCards ? 1 : 0)
                    .transition(.blurReplace)
                }
                .padding()
            }
        }
        .animation(.easeOut(duration: 1), value: showCards)
        .animation(.easeInOut, value: basalEnergy)
        .animation(.easeInOut, value: activeEnergy)
        .onAppear {
            showCards = true
            Delay(1500) {
                basalEnergy = 1826
                activeEnergy = 326
            }
        }
        .task {
            do {
                let authStatus = try await healthManager.checkAccess(readTypes: healthManager.activityTypes)

                isAuthorized = authStatus == .unnecessary
            } catch { }
        }
        .shelf {
            if isAuthorized {
                ProminentButton("Continue") {
                    onContinue()
                }
            } else {
                ProminentButton("Connect to Health", systemImage: "heart.fill") {
                    triggerHealthPermissionSheet.toggle()
                }
            }
        }
        .healthDataAccessRequest(
            store: healthManager.healthStore,
            readTypes: Set(healthManager.activityTypes),
            trigger: triggerHealthPermissionSheet
        ) { result in
            switch result {
            case .success:
                onContinue()
            case .failure(let error):
                self.error = error
            }
        }
    }
}

#Preview {
    OnboardingHealthActivityView { }
}
