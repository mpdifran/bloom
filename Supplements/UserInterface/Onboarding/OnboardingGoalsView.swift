//
//  OnboardingGoalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI
import AppUI

struct OnboardingGoalsView: View {

    let onContinue: () -> Void

    @ObservedObject private var viewModel = GoalViewModel.shared

    @State private var error: Error?

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(viewModel.goals) { goal in
                    GoalCell(
                        goal: goal,
                        isSelected: viewModel.isGoalSelected(goal)
                    )
                    .onTapGesture {
                        viewModel.toggleSelect(goal: goal)
                        feedbackGenerator.impactOccurred()
                    }
                }
                .padding()
            }
            .navigationTitle("Goals")
            .shelf {
                ProminentButton("Continue") {
                    onContinue()
                }
                .buttonBorderShape(.roundedRectangle(radius: 17))
                .disabled(viewModel.selectedGoals.isEmpty)
            }
        }
        .onAppear {
            feedbackGenerator.prepare()
        }
        .alert(error: $error)
        .task {
            do {
                try await viewModel.loadGoals()
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    OnboardingGoalsView() { }
}
