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
    @ObservedObject private var vitalsViewModel = VitalsViewModel.shared

    @State private var isAuthorized = false
    @State private var triggerHealthPermissionSheet = false
    @State private var showCards = false
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
            shareTypes: Set(healthManager.writeNutritionTypes),
            readTypes: Set(healthManager.nutritionTypes),
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

private extension OnboardingHealthNutritionView {

    func checkAuth() async {
        do {
            let authStatus = try await healthManager.checkAccess(readTypes: healthManager.nutritionTypes)

            isAuthorized = authStatus == .unnecessary
            await vitalsViewModel.refreshVitals()
        } catch { }
    }

    var vitalModel: VitalModel {
        if let nutritionSummary = vitalsViewModel.nutritionSummary {
            VitalModel(
                id: .nutrition,
                subtitle: nutritionSummary.subtitle,
                status: nutritionSummary.status.title,
                score: nutritionSummary.score,
                color: nutritionSummary.status.color,
                trend: nutritionSummary.trend
            )
        } else {
            VitalModel(
                id: .nutrition,
                subtitle: "",
                status: "No Data",
                score: 0,
                color: .gray,
                trend: .noTrend
            )
        }
    }
}

#Preview {
    OnboardingHealthNutritionView { }
}
