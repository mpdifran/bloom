//
//  Habit.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

import SwiftUI
import SwiftData

extension SchemaV1 {
    @Model
    public final class Habit: Identifiable, Sendable {
        public var targetMetric: TargetMetric?
        public var value: Double = 0
        public var vitalKind: VitalModel.Kind?
        public var context: String?

        public init(
            targetMetric: TargetMetric,
            value: Double,
            vitalKind: VitalModel.Kind? = nil,
            context: String? = nil
        ) {
            self.targetMetric = targetMetric
            self.value = value
            self.vitalKind = vitalKind
            self.context = context
        }
    }
}
