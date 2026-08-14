//
//  ExperimentOverride.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-05.
//

import Foundation

enum ExperimentOverride: String, CaseIterable {
    case original = "original"
    case control = "control"
    case treatment = "treatment"
    
    var displayName: String {
        switch self {
        case .original:
            return String(localized: "Original", comment: "Display name for experiment override")
        case .control:
            return String(localized: "Control", comment: "Display name for experiment override")
        case .treatment:
            return String(localized: "Treatment", comment: "Display name for experiment override")
        }
    }
}