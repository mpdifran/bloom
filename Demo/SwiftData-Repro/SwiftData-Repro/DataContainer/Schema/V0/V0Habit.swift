//
//  Habit.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

import SwiftUI
import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV0 {
    @Model
    public final class Habit: Identifiable {
        public var targetMetric: TargetMetric? = TargetMetric.none
        public var value: Double = 0
        public var unitString: String = ""
        public var startDate: Date = Date.now
        public var endDate: Date? = nil
        public var isSuggested: Bool = false
        public var isUserEdited: Bool = false
        public var vitalKind: VitalModel.Kind?
        public var context: String?

        public init(
            targetMetric: TargetMetric,
            value: Double,
            unitString: String,
            startDate: Date,
            endDate: Date? = nil,
            isSuggested: Bool,
            isUserEdited: Bool,
            vitalKind: VitalModel.Kind? = nil,
            context: String? = nil
        ) {
            self.targetMetric = targetMetric
            self.value = value
            self.unitString = unitString
            self.startDate = startDate
            self.endDate = endDate
            self.isSuggested = isSuggested
            self.isUserEdited = isUserEdited
            self.vitalKind = vitalKind
            self.context = context
        }
    }
}
