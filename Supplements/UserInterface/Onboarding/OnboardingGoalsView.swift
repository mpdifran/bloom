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
    @State private var proposedHabits = [ProposedHabit]()

    @ObservedObject private var habitsViewModel = HabitsViewModel.shared

    var body: some View {
        OnboardingCardTemplateView(aspectRatio: 1.3) {
            OnboardingTitleCardView(
                systemImage: "trophy.circle.fill",
                title: "Focus Areas",
                message: "Bloom will identify the best way to improve your health."
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
                .horizontallyCentered()
            } else {
                ScrollView {
                    VStack {
                        ForEachEnumerated(proposedHabits) { (index, proposedHabit) in
                            ProposedHabitCell(
                                proposedHabit: $proposedHabits[index],
                                includeActions: false
                            )
                                .transition(.scale)
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
        .tint(.mutedOrange)
        .task {
            proposedHabits = await habitsViewModel.generateProposedHabits().proposedHabits
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
