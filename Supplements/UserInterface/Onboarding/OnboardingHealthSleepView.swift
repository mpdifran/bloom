//
//  OnboardingHealthSleepView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI
import AppUI
import HealthKitUI

struct OnboardingHealthSleepView: View {
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
                title: "Sleep Data",
                message: "Bloom can use your sleep data to help you improve your sleep."
            )
            .tint(.blue)
        } bottom: {
            ScrollView {
                VStack {
                    MonthlyVitalCardCell(
                        vital: vitalModel
                    )
                    .opacity(showCards ? 1 : 0)
                    .transition(.blurReplace)
                }
                .padding()
            }
        }
        .animation(.easeOut(duration: 1), value: showCards)
        .animation(.easeInOut, value: vitalModel)
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
            readTypes: Set(healthManager.sleepTypes),
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

private extension OnboardingHealthSleepView {

    func checkAuth() async {
        do {
            let authStatus = try await healthManager.checkAccess(readTypes: healthManager.sleepTypes)

            isAuthorized = authStatus == .unnecessary
            await vitalsViewModel.refreshVitals()
        } catch { }
    }

    var vitalModel: VitalModel {
        if let sleepSummary = vitalsViewModel.sleepVitalsSummary {
            VitalModel(
                id: .sleepQuality,
                subtitle: sleepSummary.subtitleText,
                status: sleepSummary.quality.name,
                score: sleepSummary.score,
                color: sleepSummary.quality.color,
                trend: sleepSummary.trend
            )
        } else {
            VitalModel(
                id: .sleepQuality
            )
        }
    }
}

#Preview {
    OnboardingHealthSleepView { }
}
