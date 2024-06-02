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

private extension String {
    static let activitySelection = "ScreenUseController.activitySelection"
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
        isMonitoring = !deviceActivityCenter.activities.isEmpty

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

    func startMonitoring() throws {
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endDate)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true,
            warningTime: .init(minute: 15)
        )
        try deviceActivityCenter.startMonitoring(.sleep, during: schedule)
        isMonitoring = !deviceActivityCenter.activities.isEmpty
    }

    func refreshActivitySelection() {
        loadActivitySelection()
    }

    func stopMonitoring() {
        deviceActivityCenter.stopMonitoring()
        isMonitoring = !deviceActivityCenter.activities.isEmpty
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
    }
}
