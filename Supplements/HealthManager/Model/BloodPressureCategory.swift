//
//  BloodPressureCategory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-26.
//

import Foundation

enum BloodPressureCategory {
    case normal
    case elevated
    case hypertensionStage1
    case hypertensionStage2
    case hypertensiveCrisis

    var name: String {
        switch self {
        case .normal:
            "Normal"
        case .elevated:
            "Elevated"
        case .hypertensionStage1:
            "Hypertension Stage 1"
        case .hypertensionStage2:
            "Hypertension Stage 2"
        case .hypertensiveCrisis:
            "Hypertensive Crisis"
        }
    }

    var score: Double {
        switch self {
        case .normal: 1
        case .elevated: 0.8
        case .hypertensionStage1: 0.5
        case .hypertensionStage2: 0.2
        case .hypertensiveCrisis: 0
        }
    }
}
