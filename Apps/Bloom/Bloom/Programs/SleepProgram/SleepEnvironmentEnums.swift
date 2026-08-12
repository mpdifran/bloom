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
            String(localized: "Quiet")
        case .intermittentSounds:
            String(localized: "Intermittent Sounds")
        case .regularSounds:
            String(localized: "Regular Sounds")
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
            String(localized: "Dark")
        case .someLight:
            String(localized: "Some Light")
        case .bright:
            String(localized: "Bright")
        }
    }
    var id: String { rawValue }
}
