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
        case chat
    }
}

struct OnboardingRootView: View {

    var onComplete: ([ChatMessage]) -> Void

    @State private var step = Step.welcome

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch step {
            case .welcome:
                OnboardingWelcomeView {
                    setStep(.chat)
                }
            case .chat:
                OnboardingChatView { chatMessages in
                    onComplete(chatMessages)
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
    OnboardingRootView() { _ in }
}
