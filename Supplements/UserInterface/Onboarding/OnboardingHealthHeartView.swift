//
//  OnboardingHealthHeartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-16.
//

import SwiftUI
import AppUI
import HealthKitUI
import DataContainer

struct OnboardingHealthHeartView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared
    @ObservedObject private var vitalsViewModel = VitalsViewModel.shared

    @State private var isAuthorized = false
    @State private var triggerHealthPermissionSheet = false
    @State private var showCards = false
    @State private var error: Error?

    var body: some View {
        OnboardingCardTemplateView {
            OnboardingTitleCardView(
                title: "Heart Data",
                message: "Bloom can use your cardio data to help keep your heart healthy."
            )
        } bottom: {
            ScrollView {
                VStack {
                    MonthlyVitalCardCell(
                        vital: heartHealthVitalModel
                    )
                    .opacity(showCards ? 1 : 0)
                    .transition(.blurReplace)

                    MonthlyVitalCardCell(
                        vital: stressVitalModel
                    )
                    .opacity(showCards ? 1 : 0)
                    .transition(.blurReplace)
                }
                .padding()
            }
        }
        .animation(.easeOut(duration: 1), value: showCards)
        .animation(.easeInOut, value: heartHealthVitalModel)
        .onAppear {
            showCards = true
        }
        .task {
            await checkAuth()
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
            shareTypes: Set(healthManager.writeHeartTypes),
            readTypes: Set(healthManager.heartTypes),
            trigger: triggerHealthPermissionSheet
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

private extension OnboardingHealthHeartView {

    func checkAuth() async {
        do {
            let authStatus = try await healthManager.checkAccess(readTypes: healthManager.heartTypes)

            isAuthorized = authStatus == .unnecessary
            await vitalsViewModel.forceFetchVitals()
        } catch { }
    }

    var heartHealthVitalModel: VitalModel {
        if let heartHealth = vitalsViewModel.heartHealthSummary {
            VitalModel(
                id: .heartHealth,
                subtitle: heartHealth.details.subtitle,
                status: heartHealth.details.level?.name,
                score: heartHealth.details.score ?? 1,
                color: heartHealth.details.level?.color,
                barLevel: heartHealth.details.barLevel
            )
        } else {
            VitalModel(
                id: .heartHealth
            )
        }
    }

    var stressVitalModel: VitalModel {
        if let stressSummary = vitalsViewModel.stressSummary {
            VitalModel(
                id: .stressLevels,
                subtitle: stressSummary.details.subtitle,
                status: stressSummary.details.level?.name,
                score: stressSummary.score,
                color: stressSummary.details.level?.color,
                barLevel: stressSummary.barLevel
            )
        } else {
            VitalModel(
                id: .stressLevels
            )
        }
    }
}

#Preview {
    OnboardingHealthHeartView { }
}
