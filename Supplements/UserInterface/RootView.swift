//
//  RootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

struct RootView: View {
    
    @AppStorage("hasShownOnboardingV2") var hasShownOnboarding: Bool = false

    var body: some View {
        Group {
            if !hasShownOnboarding {
                OnboardingRootView { chatMessages in
                    ChatViewModel.shared.chatHistory = chatMessages
                    withAnimation {
                        hasShownOnboarding = true
                    }
                }
            } else {
                TabView {
                    InsightsView()
                    ChatView()
                    ProfileView()
                }
            }
        }
        .animation(.easeInOut(duration: 1), value: hasShownOnboarding)
    }
}

#Preview {
    RootView()
}
