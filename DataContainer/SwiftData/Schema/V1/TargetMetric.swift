//
//  TargetMetric.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

public enum TargetMetric: String, Identifiable, Codable, CaseIterable {
    public var id: Self { self }

    case stepCount
    case waterIntake
    case walkingRunningDistance
    case timeInDaylight
}
