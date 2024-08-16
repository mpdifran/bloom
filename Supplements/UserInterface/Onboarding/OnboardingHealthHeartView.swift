//
//  OnboardingHealthHeartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-16.
//

import SwiftUI
import AppUI
import HealthKitUI

struct OnboardingHealthHeartView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

    @State private var isAuthorized = false
    @State private var triggerHealthPermissionSheet = false
    @State private var showCards = false
    @State private var hrv: Double = 0
    @State private var error: Error?

    var body: some View {
        OnboardingCardTemplateView {
            HealthPrivacyCardView(
                title: "Heart Data",
                message: "Bloom can use your cardio data to help keep your heart healthy."
            )
        } bottom: {
            ScrollView {
                VStack {
                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .cardioFitness,
                            subtitle: "VO₂ Max: \(hrv) mL/min·kg",
                            status: hrv > 0 ? "Above Average" : "No Data",
                            score: 0.9,
                            color: hrv > 0 ? .green : .gray,
                            trend: hrv > 0 ? .increasing : .noTrend
                        )
                    )
                    .contentTransition(.numericText(value: hrv))
                    .opacity(showCards ? 1 : 0)
                    .transition(.blurReplace)
                }
                .padding()
            }
        }
        .animation(.easeOut(duration: 1), value: showCards)
        .animation(.easeInOut, value: hrv)
        .onAppear {
            showCards = true
            Delay(1500) {
                hrv = 43
            }
        }
        .task {
            do {
                let authStatus = try await healthManager.checkAccess(readTypes: healthManager.heartTypes)

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
            readTypes: Set(healthManager.heartTypes),
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
    OnboardingHealthHeartView { }
}
