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
        case appExplanation
        case healthKit
        case ageAndSex
        case healthGoals
        case activityLevel
        case focusAreas
        case vitals
        case notifications
    }
}

struct OnboardingRootView: View {
    let onComplete: () -> Void

    @State private var step = Step.welcome

    private let vitalsViewModel = VitalsViewModel.shared

    @ObservedObject private var healthManager = HealthManager.shared

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch step {
            case .welcome:
                OnboardingWelcomeView {
                    setStep(.appExplanation)
                }
            case .appExplanation:
                OnboardingAppExplanationView {
                    setStep(.healthKit)
                }
            case .healthKit:
                OnboardingHealthKitView {
                    setStep(.ageAndSex)
                }
            case .ageAndSex:
                OnboardingHealthAgeView {
                    setStep(.vitals)
                }
            case .vitals:
                OnboardingHealthVitalLevelsView {
                    setStep(.healthGoals)
                }
            case .healthGoals:
                OnboardingHealthGoalView {
                    setStep(.activityLevel)
                }
            case .activityLevel:
                OnboardingHealthActivityLevelView {
                    setStep(.focusAreas)
                }
            case .focusAreas:
                OnboardingFocusAreasView {
                    setStep(.notifications)
                }
            case .notifications:
                OnboardingNotificationPermissionView {
                    onComplete()
                }
            }
        }
        .tint(.mutedBlue)
        .animation(.easeInOut(duration: 1), value: step)
        .presentationCompactAdaptation(.fullScreenCover)
    }
}

private extension OnboardingRootView {

    func setStep(_ step: Step) {
        withAnimation {
            self.step = step
        }
    }
}

#Preview {
    OnboardingRootView() { }
}
