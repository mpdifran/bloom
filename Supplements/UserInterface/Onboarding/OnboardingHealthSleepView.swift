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

    @State private var isAuthorized = false
    @State private var triggerHealthPermissionSheet = false
    @State private var showCards = false
    @State private var sleepHours: Double = 0
    @State private var sleepMinutes: Double = 0
    @State private var error: Error?

    var body: some View {
        OnboardingCardTemplateView {
            HealthPrivacyCardView(
                title: "Sleep Data",
                message: "Bloom can use your sleep data to help you improve your sleep."
            )
        } bottom: {
            ScrollView {
                VStack {
                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .sleepQuality,
                            subtitle: "Avg \(sleepHours.format())h\(sleepMinutes.format())m",
                            status: sleepHours > 0 ? "Great" : "No Data",
                            score: 0.9,
                            color: sleepHours > 0 ? .blue : .gray,
                            trend: sleepHours > 0 ? .increasing : .noTrend
                        )
                    )
                    .contentTransition(.numericText(value: sleepHours))
                    .contentTransition(.numericText(value: sleepMinutes))
                    .opacity(showCards ? 1 : 0)
                    .transition(.blurReplace)
                }
                .padding()
            }
        }
        .animation(.easeOut(duration: 1), value: showCards)
        .animation(.easeInOut, value: sleepHours)
        .animation(.easeInOut, value: sleepMinutes)
        .onAppear {
            showCards = true
            Delay(1500) {
                sleepHours = 7
                sleepMinutes = 43
            }
        }
        .task {
            do {
                let authStatus = try await healthManager.checkAccess(readTypes: healthManager.sleepTypes)

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
            readTypes: Set(healthManager.sleepTypes),
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
    OnboardingHealthSleepView { }
}
