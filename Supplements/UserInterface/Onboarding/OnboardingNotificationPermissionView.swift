//
//  OnboardingNotificationPermissionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI
import AppUI

struct OnboardingNotificationPermissionView: View {
    let onContinue: () -> Void

    @State private var isAuthorized = false
    
    @State private var showNotification = false
    @State private var showNotification2 = false

    var body: some View {
        OnboardingCardTemplateView {
            OnboardingTitleCardView(
                systemImage: "bell.badge.circle.fill",
                title: "Notifications",
                message: "Bloom will send you notifications when it detects something wrong with your health, or it has a report for you to view."
            )
            .tint(.red)
        } bottom: {
            VStack {
                if showNotification {
                    MockNotificationView(
                        title: "Your Morning Report is Ready!",
                        message: "Check out your personalized report designed just for you.",
                        timestamp: "5m ago"
                    )
                    .transition(.blurReplace)
                    .sensoryFeedback(.success, trigger: showNotification)
                }

                if showNotification2 {
                    MockNotificationView(
                        title: "Your RHR is higher than normal",
                        message: "You may be stressed or getting sick.",
                        timestamp: "11m ago"
                    )
                    .transition(.blurReplace)
                    .sensoryFeedback(.success, trigger: showNotification2)
                }

                Spacer()
            }
            .padding()
        }
        .animation(.easeIn(duration: 0.5), value: showNotification)
        .animation(.easeIn(duration: 0.5), value: showNotification2)
        .onAppear {
            Delay(1000) {
                showNotification = true
            }
            Delay(1800) {
                showNotification2 = true
            }
        }
        .shelf {
            if isAuthorized {
                ProminentButton("Continue") {
                    onContinue()
                }
            } else {
                VStack {
                    ProminentButton("Enable Notifications", systemImage: "bell.badge.fill") {
                        NotificationManager.shared.requestAuthorization()
                        isAuthorized = true
                    }

                    Button("Skip") {
                        onContinue()
                    }
                    .frame(height: 44)
                }
            }
        }
    }
}

#Preview {
    OnboardingNotificationPermissionView { }
}
