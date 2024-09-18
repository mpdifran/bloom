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
        public var source: Source = Source.suggested
        public var targetMetric: TargetMetric?
        public var value: Double = 0
        public var unitString: String = ""

        @Attribute(.unique)
        public var date: Date = Date.now

        public var vitalKind: VitalModel.Kind?
        public var context: String?

        public init(
            source: Source,
            targetMetric: TargetMetric,
            value: Double,
            unitString: String,
            date: Date,
            vitalKind: VitalModel.Kind? = nil,
            context: String? = nil
        ) {
            self.source = source
            self.targetMetric = targetMetric
            self.value = value
            self.unitString = unitString
            self.date = date
            self.vitalKind = vitalKind
            self.context = context
        }
    }
}

extension SchemaV1.Habit {
    public enum Source: String, Identifiable, Codable {
        case suggested
        case user

        public var id: Self { self }
    }
}
