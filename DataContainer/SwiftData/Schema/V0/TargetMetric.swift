//
//  TargetMetric.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

import SwiftUI

public enum TargetMetric: String, Identifiable, Codable, CaseIterable, Sendable {
    public var id: Self { self }

    case none
    case stepCount
    case waterIntake
    case walkingRunningDistance // Some of these should be related
    case timeInDaylight
}

public extension TargetMetric {

    var name: String {
        switch self {
        case .none: "None"
        case .stepCount: "Steps"
        case .waterIntake: "Water Intake"
        case .walkingRunningDistance: "Walking + Running Distance"
        case .timeInDaylight: "Time in Daylight"
        }
    }

    var systemImage: String {
        switch self {
        case .none: "xmark.app"
        case .stepCount: "figure.walk"
        case .waterIntake: "waterbottle"
        case .walkingRunningDistance: "figure.walk"
        case .timeInDaylight: "sun.max.fill"
        }
    }

    var color: Color {
        switch self {
        case .none: .gray
        case .stepCount: .mutedGreen
        case .waterIntake: .mutedBlue
        case .walkingRunningDistance: .mutedGreen
        case .timeInDaylight: .mutedOrange
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
