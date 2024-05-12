//
//  SupplementsApp.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-03-21.
//

import SwiftUI

@main
struct SupplementsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                    BackgroundTaskScheduler.shared.scheduleProactiveTipTask()
                }
        }
        .backgroundTask(.appRefresh("proactive-tip")) {
            await ChatViewModel.shared.sendProactiveTip()
        }
    }
}
