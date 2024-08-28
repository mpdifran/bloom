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
        case vitalLevels
        case ageAndSex
        case activity
        case sleep
        case heart
        case nutrition
        case otherTypes
        case goals
        case notifications
    }
}

struct OnboardingRootView: View {
    let onComplete: () -> Void

    @State private var step = Step.welcome

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
                    setStep(.vitalLevels)
                }
            case .vitalLevels:
                OnboardingHealthVitalLevelsView {
                    setStep(.ageAndSex)
                }
            case .ageAndSex:
                OnboardingHealthAgeView {
                    setStep(.activity)
                }
            case .activity:
                OnboardingHealthActivityView {
                    setStep(.sleep)
                }
            case .sleep:
                OnboardingHealthSleepView {
                    setStep(.heart)
                }
            case .heart:
                OnboardingHealthHeartView {
                    setStep(.nutrition)
                }
            case .nutrition:
                OnboardingHealthNutritionView {
                    setStep(.otherTypes)
                }
            case .otherTypes:
                OnboardingHealthOtherTypesView {
                    setStep(.goals)
                }
            case .goals:
                OnboardingGoalsView {
                    setStep(.notifications)
                }
            case .notifications:
                OnboardingNotificationPermissionView {
                    onComplete()
                }
            }
        }
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
