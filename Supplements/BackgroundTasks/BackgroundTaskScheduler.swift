//
//  BackgroundTaskScheduler.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import BackgroundTasks

final class BackgroundTaskScheduler {
    static let shared = BackgroundTaskScheduler()

    private init() { }
}

extension BackgroundTaskScheduler {

    func scheduleProactiveTipTask() {
        let request = BGAppRefreshTaskRequest(identifier: "proactive-tip")

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Proactive Tip Background Task Scheduled!")
        } catch(let error) {
            print("Scheduling Error \(error.localizedDescription)")
        }
    }
}
