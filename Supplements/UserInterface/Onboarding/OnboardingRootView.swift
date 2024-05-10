//
//  OnboardingRootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

extension OnboardingRootView {
    enum Step {
        case welcome
        case healthKit
        case goals
        case supplements
    }
}

struct OnboardingRootView: View {

    var onComplete: () -> Void

    @State private var step = Step.welcome

    @ObservedObject private var supplementsViewModel = SupplementViewModel.shared
    @ObservedObject private var goalsViewModel = GoalViewModel.shared
    @ObservedObject private var healthManager = HealthManager.shared

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch step {
            case .welcome:
                OnboardingWelcomeView()
            case .healthKit:
                OnboardingHealthKitView()
            case .goals:
                OnboardingGoalsView {
                    determineNextStep()
                }
            case .supplements:
                OnboardingSupplementsView {
                    determineNextStep()
                }
            }
        }
        .animation(.easeInOut(duration: 1), value: step)
        .onAppear {
            determineNextStep()
        }
        .onChange(of: healthManager.isAuthorized, { oldValue, newValue in
            determineNextStep()
        })
        .presentationCompactAdaptation(.fullScreenCover)
    }
}

private extension OnboardingRootView {

    func determineNextStep() {
        if !healthManager.isAuthorized {
            setStep(.healthKit)
        } else if goalsViewModel.selectedGoals.isEmpty {
            setStep(.goals)
        } else if supplementsViewModel.selectedSupplements.isEmpty {
            setStep(.supplements)
        } else {
            onComplete()
            dismiss()
        }
    }

    func setStep(_ step: Step) {
        withAnimation {
            self.step = step
        }
    }
}

#Preview {
    OnboardingRootView() { }
}
