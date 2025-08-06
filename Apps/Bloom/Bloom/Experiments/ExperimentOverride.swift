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
            return "Original"
        case .control:
            return "Control"
        case .treatment:
            return "Treatment"
        }
    }
}