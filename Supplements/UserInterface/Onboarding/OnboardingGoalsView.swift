//
//  OnboardingGoalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI
import AppUI

struct OnboardingGoalsView: View {
    let onContinue: () -> Void

    @State private var isCalculatingGoals = true
    @State private var showContinue = false

    @ObservedObject private var goalsViewModel = GoalsViewModel.shared

    var body: some View {
        OnboardingCardTemplateView(aspectRatio: 1.3) {
            OnboardingTitleCardView(
                systemImage: "trophy.circle.fill",
                title: "Goals",
                message: "Bloom will now calculate your personalized goals."
            )

        } bottom: {
            if isCalculatingGoals {
                VStack(spacing: 20) {
                    Spacer()
                    CircularSpinnerView()
                        .foregroundStyle(.tint)
                    Text("Calculating...")
                        .bold()
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack {
                        ForEach(goalsViewModel.goals, id: \.self) { goalModels in
                            if let first = goalModels.first {
                                OnboardingGoalDetails(goal: first)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
        }
        .if(showContinue) {
            $0.shelf {
                ProminentButton("Continue") {
                    onContinue()
                }
            }
        }
        .animation(.easeIn(duration: 1), value: isCalculatingGoals)
        .tint(.orange)
        .task {
            await goalsViewModel.checkForUpdateGoals(force: true)
            await MainActor.run {
                Delay(3000) {
                    isCalculatingGoals = false
                }
                Delay(5000) {
                    showContinue = true
                }
            }
        }
    }
}

#Preview {
    OnboardingGoalsView { }
}
