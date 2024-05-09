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
    }
}

struct OnboardingRootView: View {

    var onComplete: () -> Void

    @State private var step = Step.welcome

    @ObservedObject private var healthManager = HealthManager.shared

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch step {
            case .welcome:
                OnboardingWelcomeView()
            case .healthKit:
                OnboardingHealthKitView()
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
