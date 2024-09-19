//
//  Habit.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

import SwiftUI
import SwiftData

extension SchemaV0 {
    @Model
    public final class Habit: Identifiable {
        public var source: Source = Source.suggested
        public var targetMetric: TargetMetric = TargetMetric.none
        public var value: Double = 0
        public var unitString: String = ""
        public var startDate: Date = Date.now
        public var endDate: Date? = nil
        public var vitalKind: VitalModel.Kind?
        public var context: String?

        public init(
            source: Source,
            targetMetric: TargetMetric,
            value: Double,
            unitString: String,
            startDate: Date,
            endDate: Date? = nil,
            vitalKind: VitalModel.Kind? = nil,
            context: String? = nil
        ) {
            self.source = source
            self.targetMetric = targetMetric
            self.value = value
            self.unitString = unitString
            self.startDate = startDate
            self.endDate = endDate
            self.vitalKind = vitalKind
            self.context = context
        }
    }
}

extension SchemaV0.Habit {
    public enum Source: String, Identifiable, Codable {
        case suggested
        case user

        public var id: Self { self }
    }
}
