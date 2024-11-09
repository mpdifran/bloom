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
            "Quiet"
        case .intermittentSounds:
            "Intermittent Sounds"
        case .regularSounds:
            "Regular Sounds"
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
            "Dark"
        case .someLight:
            "Some Light"
        case .bright:
            "Bright"
        }
    }
    var id: String { rawValue }
}
