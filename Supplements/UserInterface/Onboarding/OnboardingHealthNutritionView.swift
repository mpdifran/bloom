//
//  OnboardingHealthNutritionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-16.
//

import SwiftUI
import AppUI
import HealthKitUI

struct OnboardingHealthNutritionView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

    @State private var isAuthorized = false
    @State private var triggerHealthPermissionSheet = false
    @State private var showCards = false
    @State private var status: String = ""
    @State private var error: Error?

    var body: some View {
        OnboardingCardTemplateView {
            HealthPrivacyCardView(
                title: "Nutrition Data",
                message: "Bloom can use your nutrition data to help you eat better."
            )
        } bottom: {
            ScrollView {
                VStack {
                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .nutrition,
                            subtitle: status.isNotEmpty ? status : "Unknown",
                            status: status.isNotEmpty ? "Healthy" : "No Data",
                            score: 0.9,
                            color: status.isNotEmpty ? .green : .gray,
                            trend: status.isNotEmpty ? .increasing : .noTrend
                        )
                    )
                    .contentTransition(.symbolEffect)
                    .opacity(showCards ? 1 : 0)
                    .transition(.blurReplace)
                }
                .padding()
            }
        }
        .animation(.easeOut(duration: 1), value: showCards)
        .animation(.easeInOut, value: status)
        .onAppear {
            showCards = true
            Delay(1500) {
                status = "Slight Caloric Deficiency"
            }
        }
        .task {
            do {
                let authStatus = try await healthManager.checkAccess(readTypes: healthManager.nutritionTypes)

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
            readTypes: Set(healthManager.nutritionTypes),
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
    OnboardingHealthNutritionView { }
}
