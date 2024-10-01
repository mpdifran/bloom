//
//  TargetMetric+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-24.
//

import SwiftUI

public extension TargetMetric {

    var name: String {
        switch self {
        case .none: "None"
        case .stepCount: "Steps"
        case .waterIntake: "Water Intake"
        case .walkingRunningDistance: "Walking + Running Distance"
        case .timeInDaylight: "Time in Daylight"
        case .exerciseMinutes: "Exercise Minutes"
        case .proteinIntake: "Protein Intake"
        case .calories: "Calories"
        }
    }

    var systemImage: String {
        switch self {
        case .none: "xmark.app"
        case .stepCount: "figure.walk"
        case .waterIntake: "waterbottle"
        case .walkingRunningDistance: "figure.walk"
        case .timeInDaylight: "sun.max.fill"
        case .exerciseMinutes: "figure.step.training"
        case .proteinIntake: "fork.knife"
        case .calories: "flame"
        }
    }

    var color: Color {
        switch self {
        case .none: .gray
        case .stepCount: .mutedGreen
        case .waterIntake: .mutedBlue
        case .walkingRunningDistance: .mutedGreen
        case .timeInDaylight: .mutedOrange
        case .exerciseMinutes: .mutedGreen
        case .proteinIntake: .protein
        case .calories: .mutedOrange
        }
    }

    var measurementStyle: TargetMetric.MeasurementStyle {
        switch self {
        case .calories: .range
        default: .minimum
        }
    }

    var related: [TargetMetric] {
        switch self {
        case .stepCount, .walkingRunningDistance:
            [.stepCount, .walkingRunningDistance].filter({ $0 != self })
        default:
            []
        }
    }
}
