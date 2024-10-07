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
    case calories
    case proteinIntake
    case waterIntake
    case timeInDaylight
    case exerciseMinutes
    case stepCount
    case walkingRunningDistance
    case runDistance
    case runDuration
    case bikeDistance
    case bikeDuration
    case targetHeartRateZone1
    case targetHeartRateZone2
    case targetHeartRateZone3
    case targetHeartRateZone4
    case targetHeartRateZone5
}

public extension TargetMetric {
    enum MeasurementStyle: String, Identifiable, Codable, CaseIterable, Sendable {
        public var id: Self { self }

        case minimum
        case range
    }
}
