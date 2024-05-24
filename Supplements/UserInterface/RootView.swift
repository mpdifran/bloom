//
//  RootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

@MainActor
struct RootView: View {
    
    @AppStorage("hasShownOnboardingV2") var hasShownOnboarding: Bool = false

    @StateObject private var tabController = TabController()

    var body: some View {
        Group {
            if !hasShownOnboarding {
                OnboardingRootView { chatMessages in
                    Task {
                        await ChatViewModel.shared.parseOnboardingInfo(chatHistory: chatMessages)
                    }
                    withAnimation {
                        hasShownOnboarding = true
                    }
                }
            } else {
                TabView(selection: $tabController.activeTab) {
                    InsightsView()
                        .tag(Tab.insights)
                    ChatView()
                        .tag(Tab.chat)
                    ProfileView()
                        .tag(Tab.profile)
                }
                .environmentObject(tabController)
            }
        }
        .animation(.easeInOut(duration: 1), value: hasShownOnboarding)
    }
}

#Preview {
    RootView()
}
