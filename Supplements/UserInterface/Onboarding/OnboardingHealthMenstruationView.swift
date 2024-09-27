//
//  OnboardingHealthMenstruationView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-24.
//

import SwiftUI
import DataContainer
import AppUI

struct OnboardingHealthMenstruationView: View {
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
                title: "Cycle Tracking",
                message: "Bloom can take your current cycle phase into account."
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
            shareTypes: Set(healthManager.writeMenstrualTypes),
            readTypes: Set(healthManager.menstrualTypes),
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

private extension OnboardingHealthMenstruationView {

    func checkAuth() async {
        do {
            let authStatus = try await healthManager.checkAccess(readTypes: healthManager.menstrualTypes)

            isAuthorized = authStatus == .unnecessary
            await vitalsViewModel.refreshVitals()
        } catch { }
    }

    var vitalModel: VitalModel {
        if let menstrualSummary = vitalsViewModel.menstrualSummary {

            VitalModel(
                id: .cycleTracking,
                subtitle: menstrualSummary.subtitle,
                status: menstrualSummary.phaseName,
                score: 1,
                color: menstrualSummary.color,
                barLevel: nil
            )
        } else {
            VitalModel(
                id: .cycleTracking
            )
        }
    }
}

#Preview {
    OnboardingHealthMenstruationView { }
}
