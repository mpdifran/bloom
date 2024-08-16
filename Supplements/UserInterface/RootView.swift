//
//  RootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

@MainActor
struct RootView: View {
    
    @AppStorage("hasShownOnboardingV3") var hasShownOnboarding: Bool = false

    @StateObject private var tabController = TabController()

    var body: some View {
        Group {
            if !hasShownOnboarding {
                OnboardingRootView {
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
                .transition(.blurReplace)
            }
        }
        .animation(.easeInOut(duration: 1), value: hasShownOnboarding)
    }
}

#Preview {
    RootView()
}
