//
//  OnboardingHealthOtherTypesView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-16.
//

import SwiftUI
import AppUI
import HealthKitUI
import DataContainer

struct OnboardingHealthOtherTypesView: View {
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
                title: "Other Data",
                message: "Bloom can access other health data to keep you healthy."
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
            shareTypes: Set(healthManager.writeOtherTypes),
            readTypes: Set(healthManager.otherTypes),
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

private extension OnboardingHealthOtherTypesView {

    func checkAuth() async {
        do {
            let authStatus = try await healthManager.checkAccess(
                readTypes: healthManager.otherTypes,
                writeTypes: healthManager.writeOtherTypes
            )

            isAuthorized = authStatus == .unnecessary
            await vitalsViewModel.refreshVitals()
        } catch { }
    }

    var vitalModel: VitalModel {
        if let bodyCompositionSummary = vitalsViewModel.bodyCompositionSummary {
            VitalModel(
                id: .bodyComposition,
                subtitle: bodyCompositionSummary.subtitle,
                status: bodyCompositionSummary.details.range?.name,
                score: bodyCompositionSummary.score,
                color: bodyCompositionSummary.details.range?.color,
                trend: bodyCompositionSummary.trend
            )
        } else {
            VitalModel(
                id: .bodyComposition
            )
        }
    }
}

#Preview {
    OnboardingHealthOtherTypesView { }
}
