//
//  SleepEnvironmentEnums.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-05.
//

import Foundation

enum SleepEnvironmentTemperature: String, Identifiable, Hashable, CaseIterable {
    case cold
    case warm
    case hot

    var name: String { rawValue.capitalized }
    var id: String { rawValue }
}

enum SleepEnvironmentSound: String, Identifiable, Hashable, CaseIterable {
    case quiet
    case intermittentSounds
    case regularSounds

    var name: String {
        switch self {
        case .quiet:
            String(localized: "Quiet", comment: "Display name for sleep environment sound")
        case .intermittentSounds:
            String(localized: "Intermittent Sounds", comment: "Display name for sleep environment sound")
        case .regularSounds:
            String(localized: "Regular Sounds", comment: "Display name for sleep environment sound")
        }
    }
    var id: String { rawValue }
}

enum SleepEnvironmentDarkness: String, Identifiable, Hashable, CaseIterable {
    case dark
    case someLight
    case bright

    var name: String {
        switch self {
        case .dark:
            String(localized: "Dark", comment: "Display name for sleep environment darkness")
        case .someLight:
            String(localized: "Some Light", comment: "Display name for sleep environment darkness")
        case .bright:
            String(localized: "Bright", comment: "Display name for sleep environment darkness")
        }
    }
    var id: String { rawValue }
}
