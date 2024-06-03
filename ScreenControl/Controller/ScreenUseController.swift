//
//  DeviceActivityMonitor.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-01.
//

import SwiftUI
import Combine
import FamilyControls
import DeviceActivity
import BloomFoundation
import ManagedSettings

private extension Int {
    // This is the time before the beginning of the sleep schedule where a warning is issued.
    static let sleepWarningTimeMinutes = 15

    // This is 10 minutes of the app being in the foreground.
    static let timeExtensionTimeMinutes = 2

    // This is 15 minutes since the extension was requested.
    static let timeExtensionWallClockTimeMinutes = 15

    // This is the time before the end of the extension when a warning is issued.
    static let timeExtensionWarningTimeMinutes = 1
}

private extension String {
    static let activitySelection = "ScreenUseController.activitySelection"
    static let extensionctivitySelection = "ScreenUseController.extensionActivitySelection"
    static let startDate = "ScreenUseController.startDate"
    static let endDate = "ScreenUseController.endDate"
}

public class ScreenUseController: ObservableObject {
    public static let shared = ScreenUseController()

    @Published public var isMonitoring = false

    @Published public var activitySelection = FamilyActivitySelection() {
        didSet {
            if let data = try? JSONEncoder.main.encode(activitySelection) {
                UserDefaults.group.set(data, forKey: .activitySelection)
                UserDefaults.group.synchronize()
            }
        }
    }
    @Published public var extensionActivitySelection = FamilyActivitySelection() {
        didSet {
            if let data = try? JSONEncoder.main.encode(extensionActivitySelection) {
                UserDefaults.group.set(data, forKey: .extensionctivitySelection)
                UserDefaults.group.synchronize()
            }
        }
    }

    @Published public var startDate = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now) ?? .now {
        didSet {
            UserDefaults.group.set(startDate, forKey: .startDate)
            UserDefaults.group.synchronize()
        }
    }
    @Published public var endDate = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now {
        didSet {
            UserDefaults.group.set(endDate, forKey: .endDate)
            UserDefaults.group.synchronize()
        }
    }

    private let deviceActivityCenter = DeviceActivityCenter()

    private init() { 
        isMonitoring = deviceActivityCenter.activities.contains(.sleep)

        loadActivitySelection()
        if let startDate = UserDefaults.group.object(forKey: .startDate) as? Date {
            self.startDate = startDate
        }
        if let endDate = UserDefaults.group.object(forKey: .endDate) as? Date {
            self.endDate = endDate
        }
    }
}

public extension ScreenUseController {

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print(error)
        }
    }

    func startMonitoring(events: [DeviceActivityEvent.Name : DeviceActivityEvent] = [:]) throws {
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endDate)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true,
            warningTime: .init(minute: .sleepWarningTimeMinutes)
        )
        try deviceActivityCenter.startMonitoring(.sleep, during: schedule, events: events)
        isMonitoring = deviceActivityCenter.activities.contains(.sleep)
    }

    func refreshActivitySelection() {
        loadActivitySelection()
    }

    func stopMonitoring() {
        deviceActivityCenter.stopMonitoring()
        isMonitoring = deviceActivityCenter.activities.contains(.sleep)
    }

    func startTimeExtensionMonitoring(
        applicationToken: ApplicationToken? = nil,
        webDomainToken: WebDomainToken? = nil,
        categoryToken: ActivityCategoryToken? = nil
    ) throws {
        extensionActivitySelection.applicationTokens.insert(applicationToken)
        extensionActivitySelection.webDomainTokens.insert(webDomainToken)
        extensionActivitySelection.categoryTokens.insert(categoryToken)

        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: .now)
        let endDate = Calendar.current.date(byAdding: .minute, value: .timeExtensionWallClockTimeMinutes, to: .now) ?? .now
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endDate)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false,
            warningTime: .init(minute: .timeExtensionWarningTimeMinutes)
        )

        let event = DeviceActivityEvent(
            applications: extensionActivitySelection.applicationTokens,
            categories: extensionActivitySelection.categoryTokens,
            webDomains: extensionActivitySelection.webDomainTokens,
            threshold: .init(minute: .timeExtensionTimeMinutes)
        )

        try deviceActivityCenter.startMonitoring(
            .timeExtension,
            during: schedule,
            events: [.timeExtension : event]
        )
    }

    func resetTimeExtensionApps() {
        extensionActivitySelection = FamilyActivitySelection()
    }

    func hasEvents(for activityName: DeviceActivityName) -> Bool {
        !deviceActivityCenter.events(for: activityName).isEmpty
    }

    func deviceActivityEvent(
        activityName: DeviceActivityName,
        eventName: DeviceActivityEvent.Name
    ) -> DeviceActivityEvent? {
        deviceActivityCenter.events(for: activityName)[eventName]
    }
}

private extension ScreenUseController {

    func loadActivitySelection() {
        if
            let data = UserDefaults.group.data(forKey: .activitySelection),
            let activitySelection = try? JSONDecoder.main.decode(FamilyActivitySelection.self, from: data)
        {
            self.activitySelection = activitySelection
        }

        if
            let data = UserDefaults.group.data(forKey: .extensionctivitySelection),
            let extensionActivitySelection = try? JSONDecoder.main.decode(FamilyActivitySelection.self, from: data)
        {
            self.extensionActivitySelection = extensionActivitySelection
        }
    }
}
