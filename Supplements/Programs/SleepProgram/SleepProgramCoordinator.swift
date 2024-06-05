//
//  SleepProgramCoordinator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-05.
//

import SwiftUI
import ScreenControl

private extension String {
    static let sleepProgramStartDate = "SleepProgramCoordinator.startDate"
    static let sleepEnvironmentTemperature = "SleepProgramCoordinator.sleepEnvironmentTemperature"
    static let sleepEnvironmentSound = "SleepProgramCoordinator.sleepEnvironmentSound"
    static let sleepEnvironmentDarkness = "SleepProgramCoordinator.sleepEnvironmentDarkness"
}

final class SleepProgramCoordinator: ObservableObject {
    static let shared = SleepProgramCoordinator()

    @Published private(set) var startDate: Date? {
        didSet {
            UserDefaults.group.set(startDate, forKey: .sleepProgramStartDate)
        }
    }

    @AppStorage(.sleepEnvironmentTemperature, store: .group) var environmentTemperature = SleepEnvironmentTemperature.cold
    @AppStorage(.sleepEnvironmentSound, store: .group) var environmentSound = SleepEnvironmentSound.quiet
    @AppStorage(.sleepEnvironmentDarkness, store: .group) var environmentDarkness = SleepEnvironmentDarkness.dark

    private init() { 
        if let date = UserDefaults.group.object(forKey: .sleepProgramStartDate) as? Date {
            self.startDate = date
        }
    }
}

extension SleepProgramCoordinator {

    func startProgram() {
        startDate = .now
    }

    func stopProgram() {
        startDate = nil
        ScreenUseController.shared.stopMonitoring()
    }
}
