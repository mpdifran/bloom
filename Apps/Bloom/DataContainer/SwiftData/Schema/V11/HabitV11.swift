//
//  HabitV11.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-20.
//

import SwiftUI
import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV11 {
  @Model
  public final class Habit: Identifiable, Hashable {
    public var rawTargetMetric: String = ""
    public var rawTimePeriod: String = ""
    public var value: Double = 0
    public var unitString: String = ""
    public var startDate: Date = Date.now
    public var endDate: Date? = nil
    public var lastNotificationDate: Date? = nil
    public var isSuggested: Bool = false
    public var isUserEdited: Bool = false
    public var vitalKind: VitalModel.Kind?
    public var context: String?

    public init(
      targetMetric: TargetMetric,
      timePeriod: GoalTimePeriod,
      value: Double,
      unitString: String,
      startDate: Date,
      endDate: Date? = nil,
      lastNotificationDate: Date? = nil,
      isSuggested: Bool,
      isUserEdited: Bool,
      vitalKind: VitalModel.Kind? = nil,
      context: String? = nil
    ) {
      self.rawTargetMetric = targetMetric.rawValue
      self.rawTimePeriod = timePeriod.rawValue
      self.value = value
      self.unitString = unitString
      self.startDate = startDate
      self.endDate = endDate
      self.lastNotificationDate = lastNotificationDate
      self.isSuggested = isSuggested
      self.isUserEdited = isUserEdited
      self.vitalKind = vitalKind
      self.context = context
    }
  }
}
