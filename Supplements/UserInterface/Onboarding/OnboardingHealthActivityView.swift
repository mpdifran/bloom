//
//  OnboardingHealthActivityView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI
import AppUI
import HealthKitUI
import DataContainer

struct OnboardingHealthActivityView: View {
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
                title: "Activity Data",
                message: "Bloom can use your activity data to help ensure you get the recommended level of activity."
            )
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
            readTypes: Set(healthManager.activityTypes),
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

private extension OnboardingHealthActivityView {

    func checkAuth() async {
        do {
            let authStatus = try await healthManager.checkAccess(readTypes: healthManager.activityTypes)

            isAuthorized = authStatus == .unnecessary
            await vitalsViewModel.refreshVitals()
        } catch { }
    }

    var vitalModel: VitalModel {
        if let activitySummary = vitalsViewModel.activityLevelSummary {
            VitalModel(
                id: .activityLevel,
                subtitle: activitySummary.subtitle,
                status: activitySummary.details.activityLevel?.name,
                score: activitySummary.details.score,
                color: activitySummary.details.activityLevel?.color,
                barLevel: activitySummary.barLevel
            )
        } else {
            VitalModel(
                id: .activityLevel
            )
        }
    }
}

#Preview {
    OnboardingHealthActivityView { }
}
