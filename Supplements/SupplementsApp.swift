//
//  SupplementsApp.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-03-21.
//

import SwiftUI
import ScreenControl
import OpenAPIClient
import Bugsnag
import BugsnagPerformance
import TelemetryDeck

@main
struct SupplementsApp: App {

    private let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

    init() {
        Bugsnag.start()
        BugsnagPerformance.start()

        TelemetryDeck.initialize(config: .init(appID: "764D40B8-F2CE-4372-87D3-0D68F34E08CA"))

        OpenAPIClientAPI.basePath = "https://shep-test-7d27e987b8ef.herokuapp.com/api"
        OpenAPIClientAPI.apiResponseQueue = DispatchQueue(label: "OpenAPIQueue")
    }

    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    BackgroundTaskScheduler.shared.scheduleProactiveTipTask()
                    Task {
                        await MainActor.run {
                            HealthManager.shared.observeSleepData()
                        }
                    }
                }
                .onReceive(foregroundPublisher) { _ in

                }
        }
        .modelContainer(ContainerHolder.shared.container)
        .backgroundTask(.appRefresh("proactive-tip")) {
            if danieleMode {
                await ProactiveTipper.shared.sendProactiveTip()
            }
            await GoalsViewModel.shared.checkForUpdateGoals()
            BackgroundTaskScheduler.shared.scheduleProactiveTipTask()
        }
    }
}
