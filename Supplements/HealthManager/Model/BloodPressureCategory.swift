//
//  BloodPressureCategory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-26.
//

import SwiftUI

enum BloodPressureCategory: CaseIterable, Identifiable {
    var id: Self { self }

    case low
    case normal
    case elevated
    case hypertensionStage1
    case hypertensionStage2
    case hypertensiveCrisis

    var name: String {
        switch self {
        case .low:
            "Low"
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

    var color: Color {
        switch self {
        case .low, .elevated: return .vitalWarning
        case .normal: return .vitalGood
        case .hypertensionStage1, .hypertensionStage2: return .vitalSevere
        case .hypertensiveCrisis: return .pink
        }
    }

    var description: String {
        switch self {
        case .low:
            "Low blood pressure can be normal for some people, especially if they have no symptoms. However, when blood pressure drops too low, it can cause inadequate blood flow to the organs, leading to symptoms like dizziness, fainting, and in severe cases, shock."
        case .normal:
            "This range is considered optimal and indicates that the heart is functioning well without excessive strain on the blood vessels."
        case .elevated:
            "Blood pressure in this range is higher than normal but not yet in the high blood pressure range. It suggests that there may be an increased risk of developing hypertension."
        case .hypertensionStage1:
            "This stage indicates the beginning of high blood pressure, where there’s increased force on the arteries, potentially leading to health issues if not managed."
        case .hypertensionStage2:
            "Blood pressure at this stage is significantly high, posing a greater risk for heart disease, stroke, and other complications. It often requires medication and lifestyle changes to control."
        case .hypertensiveCrisis:
            "This is a critical condition where blood pressure is dangerously high, requiring immediate medical attention to prevent severe damage to organs."
        }
    }
}
