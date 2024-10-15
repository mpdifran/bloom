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

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch step {
            case .welcome:
                OnboardingWelcomeView {
                    setStep(.healthKit)
                }
            case .healthKit:
                OnboardingHealthKitView {
                    setStep(.ageAndSex)
                }
            case .ageAndSex:
                OnboardingHealthAgeView {
                    setStep(.healthGoals)
                }
            case .healthGoals:
                OnboardingHealthGoalView {
                    if let _ = vitalsViewModel.activityLevelSummary?.details.activityLevel {
                        setStep(.vitals)
                    } else {
                        setStep(.activityLevel)
                    }
                }
            case .activityLevel:
                OnboardingHealthActivityLevelView {
                    setStep(.vitals)
                }
            case .vitals:
                OnboardingHealthVitalLevelsView {
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
