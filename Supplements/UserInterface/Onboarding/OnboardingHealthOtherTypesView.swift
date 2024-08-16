//
//  OnboardingHealthOtherTypesView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-16.
//

import SwiftUI
import AppUI
import HealthKitUI

struct OnboardingHealthOtherTypesView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

    @State private var isAuthorized = false
    @State private var triggerHealthPermissionSheet = false
    @State private var showCards = false
    @State private var bodyFat: Double = 0
    @State private var error: Error?

    var body: some View {
        OnboardingCardTemplateView {
            HealthPrivacyCardView(
                title: "Other  Data",
                message: "Bloom can access other health data to keep you healthy."
            )
        } bottom: {
            ScrollView {
                VStack {
                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .bodyComposition,
                            subtitle: "\(bodyFat.format())% Body Fat",
                            status: bodyFat > 0 ? "Healthy" : "No Data",
                            score: 0.9,
                            color: bodyFat > 0 ? .green : .gray,
                            trend: bodyFat > 0 ? .decreasing : .noTrend
                        )
                    )
                    .contentTransition(.numericText(value: bodyFat))
                    .opacity(showCards ? 1 : 0)
                    .transition(.blurReplace)
                }
                .padding()
            }
        }
        .animation(.easeOut(duration: 1), value: showCards)
        .animation(.easeInOut, value: bodyFat)
        .onAppear {
            showCards = true
            Delay(1500) {
                bodyFat = 22
            }
        }
        .task {
            do {
                let authStatus = try await healthManager.checkAccess(readTypes: healthManager.otherTypes)

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
            readTypes: Set(healthManager.otherTypes),
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
    OnboardingHealthOtherTypesView { }
}
