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
                    VitalsView()
                        .tag(Tab.vitals)
//                    CorrelationsView()
//                        .tag(Tab.correlations)
                    GoalsView()
                        .tag(Tab.goals)
                    ChatView()
                        .tag(Tab.chat)
                    PreferencesView()
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
