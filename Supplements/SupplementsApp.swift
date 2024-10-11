//
//  SupplementsApp.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-03-21.
//

import SwiftUI
import ScreenControl
import Bugsnag
import BugsnagPerformance
import TelemetryDeck
import DataContainer

@main
struct SupplementsApp: App {

    private let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

    init() {
        Bugsnag.start()
        BugsnagPerformance.start()

        TelemetryDeck.initialize(config: .init(appID: "764D40B8-F2CE-4372-87D3-0D68F34E08CA"))

        Task {
            await HealthSleepObserver.shared.observeSleep()
        }

//        BackgroundTaskScheduler.shared.scheduleProactiveTipTask()
    }

    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.accent)
                .onReceive(foregroundPublisher) { _ in
                    onForeground()
                }
                .task {
                    await VitalsCalculator.shared.refreshVitals()
                }
        }
        .modelContainer(ContainerHolder.shared.container)
//        .backgroundTask(.appRefresh("proactive-tip")) {
//            if await danieleMode {
//                await ProactiveTipper.shared.sendProactiveTip()
//            }
//            BackgroundTaskScheduler.shared.scheduleProactiveTipTask()
//        }
    }
}

private extension SupplementsApp {

    func onForeground() {
        Task {
            await VitalsCalculator.shared.refreshVitals()
        }
    }
}
