//
//  SupplementsApp.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-03-21.
//

import SwiftUI
import ScreenControl
import OpenAPIClient

@main
struct SupplementsApp: App {

    private let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

    init() {
        OpenAPIClientAPI.basePath = "https://shep-test-7d27e987b8ef.herokuapp.com/api"
        OpenAPIClientAPI.apiResponseQueue = DispatchQueue(label: "OpenAPIQueue")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                    BackgroundTaskScheduler.shared.scheduleProactiveTipTask()
                    LocationManager.shared.requestAuth()
                    Task {
                        await HealthManager.shared.requestAccessIfNeeded()
                        await MainActor.run {
                            HealthManager.shared.observeSleepData()
                        }
                        await ScreenUseController.shared.requestAuthorization()
                    }
                }
                .onReceive(foregroundPublisher) { _ in
                    Task {
                        do {
                            try await HealthManager.shared.loadUserInfo()
                        } catch {
                            print(error)
                        }
                    }
                }
        }
        .backgroundTask(.appRefresh("proactive-tip")) {
            await ChatViewModel.shared.sendProactiveTip()
            BackgroundTaskScheduler.shared.scheduleProactiveTipTask()
        }
    }
}
