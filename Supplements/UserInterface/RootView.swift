//
//  RootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

struct RootView: View {
    
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false

    @State private var presentedSheet: AnyView?
    @State private var error: Error?

    var body: some View {
        TabView {
            GoalsView()
            ChatView()
        }
        .sheet($presentedSheet)
        .alert(error: $error)
        .onAppear {

            checkOnboarding()
        }
    }
}

extension RootView {

    func checkOnboarding(force: Bool = false) {
        if force {
            hasShownOnboarding = false
        }

        guard !hasShownOnboarding || !HealthManager.shared.isAuthorized else { return }

        presentedSheet = OnboardingRootView(onComplete: {
            hasShownOnboarding = true
        }).asAny
    }
}

#Preview {
    RootView()
}
