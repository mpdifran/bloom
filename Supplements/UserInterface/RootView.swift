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
    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    @Bindable private var tabController = TabController()

    @Environment(\.dismiss) private var dismiss

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
                    TodayView()
                        .tag(Tab.today)
                    VitalsView()
                        .tag(Tab.vitals)
                    ActionsView()
                        .tag(Tab.actions)
                    if danieleMode {
                        ChatView()
                            .tag(Tab.chat)
                    }
                    PreferencesView()
                        .tag(Tab.profile)
                }
                .environment(tabController)
                .transition(.blurReplace)
            }
        }
        .animation(.easeInOut(duration: 1), value: hasShownOnboarding)
        .animation(.default, value: danieleMode)
        .onChange(of: tabController.toggleToDismiss) { oldValue, newValue in
            dismiss()
        }
    }
}

#Preview {
    RootView()
}
