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
    case walkingRunningDistance
    case timeInDaylight
    case exerciseMinutes
}
