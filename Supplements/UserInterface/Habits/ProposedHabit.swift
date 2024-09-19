//
//  ProposedHabit.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import DataContainer

struct ProposedHabit: Sendable, Identifiable {
    let id = UUID()
    let targetMetric: TargetMetric
    let value: Double
    let unitString: String
    let startDate: Date = Date.now
    let vitalKind: VitalModel.Kind?
    let context: String?
}
